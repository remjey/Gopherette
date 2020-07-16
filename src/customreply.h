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

#ifndef GOPHERREPLY_H
#define GOPHERREPLY_H

#include "geminicertificatemanager.h"

#include <QNetworkReply>
#include <QObject>
#include <QSslSocket>

class CustomReply : public QNetworkReply
{
Q_OBJECT
public:
    CustomReply(const QNetworkRequest &request, QObject *parent);
    ~CustomReply() override;

    bool open(OpenMode mode) override;
    qint64 bytesAvailable() const override;
    void close() override;

    void acceptCertificate();

    bool isSequential() const override;
    bool canReadLine() const override;

public slots:
    void abort() override;

signals:
    void geminiCertificateUnknown(QString fp, bool cn_ok, QString cns);
    void geminiCertificateChanged(QString fp, bool cn_ok, QString cns);

protected:
    qint64 readData(char *data, qint64 maxSize) override;
    qint64 writeData(const char *data, qint64 len) override;

    bool request_sent;
    QSslSocket *socket;
    QByteArray buf;
    bool gemini;
    bool gemini_response_header_received;
    bool gemini_finished;

protected slots:
    void socket_connected();
    void socket_readyRead();
    void socket_error(QAbstractSocket::SocketError socketError);
    void socket_disconnected();
    void socket_sslErrors(const QList<QSslError> &errs);
    /*
    void socket_modeChanged(QSslSocket::SslMode);
    void socket_stateChanged(QAbstractSocket::SocketState);
    void socket_aboutToClose();
    void socket_readChannelFinished();
    */

private:
    GeminiCertificateManager *gcm;
    void send_request();
    void fail(QNetworkReply::NetworkError err);
};

#endif // GOPHERREPLY_H
