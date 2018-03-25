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

#include <QNetworkReply>
#include <QObject>
#include <QTcpSocket>

class GopherReply : public QNetworkReply
{
public:
    GopherReply(const QNetworkRequest &request, QObject *parent);
    virtual bool open(OpenMode mode);
    virtual qint64 bytesAvailable() const;
    virtual void close();

    virtual bool isSequential() const;
    virtual qint64 pos() const;
    virtual qint64 size() const;

public slots:
    virtual void abort();

protected:
    virtual qint64 readData(char *data, qint64 maxSize);
    virtual qint64 writeData(const char *data, qint64 len);

    QTcpSocket socket;
    QByteArray buf;

protected slots:
    void socket_connected();
    void socket_readyRead();
    void socket_error(QAbstractSocket::SocketError socketError);
    void socket_disconnected();

};

#endif // GOPHERREPLY_H
