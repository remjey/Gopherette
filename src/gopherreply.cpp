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

#include "gopherreply.h"

#include <QMetaEnum>

GopherReply::GopherReply(const QNetworkRequest &request, QObject *parent)
    : QNetworkReply(parent),
      gemini(request.url().scheme() == "gemini"), gemini_response_header_received(false)
{
    setRequest(request);
    socket = new QSslSocket(this);
    connect(socket, &QIODevice::readyRead, this, &GopherReply::socket_readyRead);
    if (gemini)
        connect(socket, &QSslSocket::encrypted, this, &GopherReply::socket_connected);
    else
        connect(socket, &QSslSocket::connected, this, &GopherReply::socket_connected);
    connect(socket, static_cast<void(QAbstractSocket::*)(QAbstractSocket::SocketError)>(&QAbstractSocket::error), this, &GopherReply::socket_error);
    connect(socket, &QAbstractSocket::disconnected, this, &GopherReply::socket_disconnected);
    connect(socket, static_cast<void(QSslSocket::*)(const QList<QSslError>&)>(&QSslSocket::sslErrors), this, &GopherReply::socket_sslErrors);
    /*
    connect(socket, &QSslSocket::modeChanged, this, &GopherReply::socket_modeChanged);
    connect(socket, &QAbstractSocket::stateChanged, this, &GopherReply::socket_stateChanged);
    connect(socket, &QAbstractSocket::aboutToClose, this, &GopherReply::socket_aboutToClose);
    connect(socket, &QAbstractSocket::readChannelFinished, this, &GopherReply::socket_readChannelFinished);
    */
}

GopherReply::~GopherReply()
{

}

bool GopherReply::open(QIODevice::OpenMode mode)
{
    QIODevice::open(mode);
    if (gemini) {
        socket->setProtocol(QSsl::TlsV1_2OrLater);
        socket->setPeerVerifyMode(QSslSocket::PeerVerifyMode::QueryPeer);
        socket->connectToHostEncrypted(request().url().host(), request().url().port(1965));
    } else {
        socket->connectToHost(request().url().host(), request().url().port(70));
    }
    return true;
}

qint64 GopherReply::bytesAvailable() const
{
    return buf.size() + QIODevice::bytesAvailable();
}

void GopherReply::close()
{
    socket->close();
}

bool GopherReply::isSequential() const
{
    return true;
}

void GopherReply::abort()
{
    socket->close();
}

bool GopherReply::canReadLine() const
{
    return QIODevice::canReadLine() || buf.contains('\n')
            || ((socket->state() == QAbstractSocket::UnconnectedState
                 || socket->state() == QAbstractSocket::ClosingState)
                && bytesAvailable());
}

qint64 GopherReply::readData(char *data, qint64 maxSize)
{
    if (gemini && !gemini_response_header_received) return 0;

    qint64 n = std::min(maxSize, static_cast<qint64>(buf.size()));
    memcpy(data, buf.data(), n);
    buf.remove(0, n);
    return n;
}

qint64 GopherReply::writeData(const char *, qint64)
{
    return -1;
}

void GopherReply::socket_connected()
{
    QByteArray b;
    if (gemini) {
        // Send full URL
        b = request().url().toString().toUtf8();
    } else {
        b = request().url().path().mid(2).toLatin1(); // Send path only, skip first slash and type
    }
    qInfo("socket_connected, sending request: %s", b.data());
    b.append("\r\n");
    socket->write(b);
}

void GopherReply::fail(QNetworkReply::NetworkError err) {
    buf.clear();
    socket->close();
    error(err);
}

void GopherReply::socket_readyRead()
{
    qInfo("socket_readyRead");
    QByteArray data = socket->readAll();
    buf.append(data);
    if (gemini && !gemini_response_header_received) {
        auto pos = buf.indexOf("\r\n");
        if (pos >= 1024 + 3) {
            // Response header too long
            fail(QNetworkReply::NetworkError::ProtocolFailure);
        } else if (pos >= 3) {
            if (QChar(buf.at(0)).isDigit() && QChar(buf.at(1)).isDigit() && (buf.at(2) == ' ' || buf.at(2) == '\t')) {
                if (buf.at(2) == '\t') qInfo("Non compliant server: sent a tab instead of a space after the status code");
                char status_digit = buf.at(0);
                setRawHeader("x-gemini-status", buf.mid(0, 2));
                setRawHeader("x-gemini-meta", buf.mid(3, pos - 3));
                gemini_response_header_received = true;
                buf.remove(0, pos + 2);
                // TODO use redirected() signal for redirects
                if (status_digit == '2') {
                    downloadProgress(buf.size(), -1);
                    if (buf.size() != 0) readyRead();
                } else if (status_digit == '3') {
                    redirected(QUrl(rawHeader("x-gemini-meta")));
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

void GopherReply::socket_error(QAbstractSocket::SocketError socketError)
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

void GopherReply::socket_disconnected()
{
    if (gemini && !gemini_response_header_received) {
        error(QNetworkReply::NetworkError::RemoteHostClosedError);
    }
    finished();
}

void GopherReply::socket_sslErrors(const QList<QSslError> &errs)
{
    qInfo("SSL Errors:");
    for (auto &err : errs) {
        qInfo() << err.error() << ": " << err.errorString();
    }
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
