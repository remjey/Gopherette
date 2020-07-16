/* This file is part of Gopherette, the SailfishOS Gopher-space browser.
 * Copyright (C) 2018 - Jérémy Farnaud
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "customreply.h"

#include <QMetaEnum>
#include <QSslKey>

CustomReply::CustomReply(const QNetworkRequest &request, QObject *parent)
    : QNetworkReply(parent),
      request_sent(false),
      gemini(request.url().scheme() == "gemini"),
      gemini_response_header_received(false),
      gemini_finished(false),
      gemini_accept_certificate(false),
      gcm(new GeminiCertificateManager(this))
{
    setRequest(request);
    socket = new QSslSocket(this);
    connect(socket, &QIODevice::readyRead, this, &CustomReply::socket_readyRead);
    if (gemini)
        connect(socket, &QSslSocket::encrypted, this, &CustomReply::socket_connected);
    else
        connect(socket, &QSslSocket::connected, this, &CustomReply::socket_connected);
    connect(socket, static_cast<void(QAbstractSocket::*)(QAbstractSocket::SocketError)>(&QAbstractSocket::error), this, &CustomReply::socket_error);
    connect(socket, &QAbstractSocket::disconnected, this, &CustomReply::socket_disconnected);
    connect(socket, static_cast<void(QSslSocket::*)(const QList<QSslError>&)>(&QSslSocket::sslErrors), this, &CustomReply::socket_sslErrors);
    /*
    connect(socket, &QSslSocket::modeChanged, this, &GopherReply::socket_modeChanged);
    connect(socket, &QAbstractSocket::stateChanged, this, &GopherReply::socket_stateChanged);
    connect(socket, &QAbstractSocket::aboutToClose, this, &GopherReply::socket_aboutToClose);
    connect(socket, &QAbstractSocket::readChannelFinished, this, &GopherReply::socket_readChannelFinished);
    */
}

CustomReply::~CustomReply()
{

}

bool CustomReply::open(QIODevice::OpenMode mode)
{
    if (!QIODevice::open(mode)) return false;
    if (gemini) {
        QSslConfiguration sslConf;
        sslConf.setProtocol(QSsl::TlsV1_2OrLater);
        sslConf.setCaCertificates({});
        sslConf.setPeerVerifyMode(QSslSocket::PeerVerifyMode::QueryPeer);
        sslConf.setPeerVerifyDepth(1);
        socket->setSslConfiguration(sslConf);
        socket->connectToHostEncrypted(request().url().host(), static_cast<uint16_t>(request().url().port(1965)));
    } else {
        socket->connectToHost(request().url().host(), static_cast<uint16_t>(request().url().port(70)));
    }
    return true;
}

qint64 CustomReply::bytesAvailable() const
{
    if (gemini_finished)
        return 0;
    else
        return buf.size() + QIODevice::bytesAvailable();
}

void CustomReply::close()
{
    socket->close();
}

void CustomReply::acceptCertificate()
{
    if (socket_cert.isNull()) {
        gemini_accept_certificate = true;
    } else {
        gcm->update_server(request().url().host(), request().url().port(1965), socket_cert);
        send_request();
    }
}

bool CustomReply::isSequential() const
{
    return true;
}

void CustomReply::abort()
{
    error(QNetworkReply::NetworkError::OperationCanceledError);
    socket->close();
}

bool CustomReply::canReadLine() const
{
    if (gemini_finished) return false;

    return QIODevice::canReadLine() || buf.contains('\n')
            || ((socket->state() == QAbstractSocket::UnconnectedState
                 || socket->state() == QAbstractSocket::ClosingState)
                && bytesAvailable());
}

qint64 CustomReply::readData(char *data, qint64 maxSize)
{
    if ((gemini && !gemini_response_header_received) || gemini_finished) return 0;

    int n = std::min(static_cast<int>(maxSize), buf.size());
    memcpy(data, buf.data(), static_cast<size_t>(n));
    buf.remove(0, n);
    return n;
}

qint64 CustomReply::writeData(const char *, qint64)
{
    return -1;
}

void CustomReply::socket_connected()
{
    qInfo("Socket connected");
    if (gemini) {
        socket_cert = socket->peerCertificate();
        QString fp, hostname;
        hostname = request().url().host();
        auto cert_result = gcm->check_server(request().url().host(), request().url().port(1965), socket_cert, &fp);
        if (cert_result != GeminiCertificateManager::ServerCertificateOK) {
            if (gemini_accept_certificate) {
                acceptCertificate();
                return;
            }

            auto cn_list = socket_cert.subjectInfo(QSslCertificate::CommonName);
            bool cn_ok = cn_list.contains(hostname);

            if (cert_result == GeminiCertificateManager::ServerCertificateUnknown) {
                geminiCertificateUnknown(fp, cn_ok, cn_list.join(", "));
                return;
            } else if (cert_result == GeminiCertificateManager::ServerCertificateChanged) {
                geminiCertificateChanged(fp, cn_ok, cn_list.join(", "));
                return;
            }
        }
    }

    send_request();
}

void CustomReply::fail(QNetworkReply::NetworkError err)
{
    gemini_finished = true;
    buf.clear();
    socket->close();
    error(err);
}

void CustomReply::socket_readyRead()
{
    QByteArray data = socket->readAll();
    buf.append(data);
    if (gemini && !gemini_response_header_received) {
        auto pos = buf.indexOf("\r\n");
        if (pos >= 1024 + 3) {
            // Response header too long
            fail(QNetworkReply::NetworkError::ProtocolFailure);
        } else if (pos >= 2) {
            if (QChar(buf.at(0)).isDigit() && QChar(buf.at(1)).isDigit() && (pos == 2 || buf.at(2) == ' ' || buf.at(2) == '\t')) {
                if (pos == 2)
                    qInfo("Non compliant server: sent a status-only header");
                else
                    if (buf.at(2) == '\t') qInfo("Non compliant server: sent a tab instead of a space after the status code");

                char status_digit = buf.at(0);
                QString meta = pos == 2 ? "" : QString::fromUtf8(buf.mid(3, pos - 3));
                if (status_digit == '2' && meta.isEmpty()) meta = "text/gemini; charset=utf-8";

                setRawHeader("x-gemini-status", buf.mid(0, 2));
                setRawHeader("x-gemini-meta", meta.toUtf8());

                gemini_response_header_received = true;
                buf.remove(0, pos + 2);
                metaDataChanged();

                if (status_digit == '1') {
                    gemini_finished = true;
                    socket->close();
                } else if (status_digit == '2') {
                    downloadProgress(buf.size(), -1);
                    if (buf.size() != 0) readyRead();
                } else if (status_digit == '3') {
                    redirected(QUrl(rawHeader("x-gemini-meta")));
                    gemini_finished = true;
                    socket->close();
                } else if (status_digit == '4') {
                    fail(QNetworkReply::NetworkError::ServiceUnavailableError);
                } else if (status_digit == '5') {
                    fail(QNetworkReply::NetworkError::ContentNotFoundError);
                } else if (status_digit == '6') {
                    fail(QNetworkReply::NetworkError::AuthenticationRequiredError);
                } else {
                    // Unsupported status
                    fail(QNetworkReply::NetworkError::ProtocolUnknownError);
                }
            } else {
                // Invalid response header
                fail(QNetworkReply::NetworkError::ProtocolFailure); //TODO
            }

        } else if (pos >= 0) {
            // Too short
            fail(QNetworkReply::NetworkError::ProtocolFailure); //TODO
        } else if (buf.size() >= 1024 + 5) {
            // Too long without a valid header
            fail(QNetworkReply::NetworkError::ProtocolFailure); //TODO
        }

    } else {
        downloadProgress(pos() + buf.size(), -1);
        readyRead();
    }
}

void CustomReply::socket_error(QAbstractSocket::SocketError socketError)
{
    if (socketError == QAbstractSocket::SocketError::RemoteHostClosedError) {
        socket->close();
        return;
    }

    qInfo() << "Socket error:" << QMetaEnum::fromType<QAbstractSocket::SocketError>().valueToKey(socketError);
    switch (socketError) {
    case QAbstractSocket::ConnectionRefusedError:
        fail(ConnectionRefusedError); break;
    case QAbstractSocket::HostNotFoundError:
        fail(HostNotFoundError); break;
    case QAbstractSocket::SocketTimeoutError:
        fail(TimeoutError); break;
    case QAbstractSocket::SslHandshakeFailedError:
    case QAbstractSocket::SslInvalidUserDataError:
        fail(SslHandshakeFailedError); break;
    default:
        fail(UnknownNetworkError);
    }
}

void CustomReply::socket_disconnected()
{
    if (gemini && !gemini_response_header_received) {
        error(QNetworkReply::NetworkError::RemoteHostClosedError);
    }
    finished();
}

void CustomReply::socket_sslErrors(const QList<QSslError> &errs)
{
    qInfo("SSL Errors:");
    for (auto &err : errs) {
        qInfo() << err.error() << ": " << err.errorString();
    }
}

void CustomReply::send_request()
{
    if (request_sent) return;
    request_sent = true;

    QByteArray b;
    if (gemini) {
        // Send full URL
        b = request().url().toEncoded();
    } else {
        b = request().url().path().mid(2).toLatin1(); // Send path only, skip first slash and type
        if (request().url().hasQuery()) {
            b.append('\t').append(request().url().query(QUrl::FullyDecoded).toLatin1());
        }
    }

    qInfo("Sending request: %s", b.data());
    b.append("\r\n");
    socket->write(b);
}

/*
void GopherReply::socket_modeChanged(QSslSocket::SslMode mode)
{
    qInfo() << "Socket mode changed: " << mode;
}

void GopherReply::socket_stateChanged(QAbstractSocket::SocketState state)
{
    qInfo() << "Socket state changed: " << QMetaEnum::fromType<QAbstractSocket::SocketState>().valueToKey(state);
}

void GopherReply::socket_aboutToClose()
{
    qInfo() << "Socket about to close";
}

void GopherReply::socket_readChannelFinished()
{
    qInfo() << "Socket read channel finished";
}
*/
