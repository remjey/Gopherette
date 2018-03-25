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

GopherReply::GopherReply(const QNetworkRequest &request, QObject *parent)
    : QNetworkReply(parent)
{
    setRequest(request);
    connect(&socket, &QIODevice::readyRead, this, &GopherReply::socket_readyRead);
    connect(&socket, &QAbstractSocket::connected, this, &GopherReply::socket_connected);
    connect(&socket, static_cast<void(QAbstractSocket::*)(QAbstractSocket::SocketError)>(&QAbstractSocket::error), this, &GopherReply::socket_error);
    connect(&socket, &QAbstractSocket::disconnected, this, &GopherReply::socket_disconnected);
}

bool GopherReply::open(QIODevice::OpenMode mode)
{
    QIODevice::open(mode);
    socket.connectToHost(request().url().host(), request().url().port());
    return true;
}

qint64 GopherReply::bytesAvailable() const
{
    return buf.size();
}

void GopherReply::close()
{
    socket.close();
}

bool GopherReply::isSequential() const
{
    return true;
}

qint64 GopherReply::pos() const
{
    return -1;
}

qint64 GopherReply::size() const
{
    return -1;
}

void GopherReply::abort()
{
    socket.close();
}

qint64 GopherReply::readData(char *data, qint64 maxSize)
{
    qint64 n = std::min(maxSize, (qint64)buf.size());
    memcpy(data, buf.data(), n);
    buf.remove(0, n);
    qInfo() << "Read " << QString::number(n);
    return n;
}

qint64 GopherReply::writeData(const char *, qint64)
{
    return -1;
}

void GopherReply::socket_connected()
{
    qInfo("Connected");
    QByteArray b = request().url().path().mid(2).toLatin1(); // skip first slash and type
    b.append("\r\n");
    socket.write(b);
}

void GopherReply::socket_readyRead()
{
    QByteArray data = socket.readAll();
    qInfo() << "Received " << QString::number(data.size());
    buf.append(data);
    downloadProgress(data.size(), -1);
}

void GopherReply::socket_error(QAbstractSocket::SocketError socketError)
{
    if (socketError == QAbstractSocket::SocketError::RemoteHostClosedError) return;
    qInfo("Error");
    socket.close();
    error(QNetworkReply::NetworkError::UnknownNetworkError); //TODO
}

void GopherReply::socket_disconnected()
{
    qInfo("Disconnected");
    socket.close();
    finished();
}

