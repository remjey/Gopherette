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

#include "gopherrequest.h"

#include <QtDebug>
#include <QMetaEnum>

GopherRequest::Encoding encodingOf(const QByteArray& ba) {
    bool has_utf8 = false;
    int utf8_rem = 0;
    for (char c : ba) {
        if ((c & 0xf8) == 0xf0 && utf8_rem == 0) {
            // 0x11110xxx
            utf8_rem = 3;
            has_utf8 = true;
        } else if ((c & 0xf0) == 0xe0 && utf8_rem == 0) {
            // 0x1110xxxx
            utf8_rem = 2;
            has_utf8 = true;
        } else if ((c & 0xe0) == 0xc0 && utf8_rem == 0) {
            // 0x110xxxxx
            utf8_rem = 1;
            has_utf8 = true;
        } else if ((c & 0xc0) == 0x80) {
            // 0x10xxxxxx
            if (utf8_rem == 0) {
                return GopherRequest::EncLatin1;
            } else {
                --utf8_rem;
            }
        } else if ((c & 0x80) == 0) {
            // 0x0xxxxxxx (ASCII)
            if (utf8_rem > 0) {
                // This is invalid UTF8, switch to Latin1
                return GopherRequest::EncLatin1;
            } else {
                // Not sure
            }
        } else {
            // Not ASCIII, not correct UTF8
            // (supposedly 0x11111xxx and invalid UTF8
            return GopherRequest::EncLatin1;
        }
    }
    if (has_utf8) {
        if (utf8_rem == 0) return GopherRequest::EncUTF8;
        else return GopherRequest::EncLatin1; // Invalid UTF8
    }
    // Only ASCII text was encountered
    return GopherRequest::EncAuto;
}

GopherRequest::GopherRequest(QObject *parent) : QObject(parent)
{
    running = false;
    ended = false;
    connect(&socket, &QIODevice::readyRead, this, &GopherRequest::readyRead);
    connect(&socket, &QAbstractSocket::connected, this, &GopherRequest::connected);
    connect(&socket, static_cast<void(QAbstractSocket::*)(QAbstractSocket::SocketError)>(&QAbstractSocket::error), this, &GopherRequest::error);
    connect(&socket, &QAbstractSocket::disconnected, this, &GopherRequest::disconnected);
}

void GopherRequest::open(QString host, quint16 port, QString selector, QString type, Encoding enc)
{
    if (running) return;

    this->enc = enc;
    this->type = type;
    this->selector = selector;

    ended = false;
    running = true;
    r_start();
    socket.connectToHost(host, port);
    qInfo() << "Gopher request type " + type + " to " + host + ":" + QString::number(port) + " selector " + selector;
}

void GopherRequest::connected()
{
    qInfo() << "Connected, send selector";
    QByteArray req;
    if (enc == EncUTF8) req = (selector + "\r\n").toUtf8();
    else req = (selector + "\r\n").toLatin1();
    socket.write(req);
}

void GopherRequest::error(QAbstractSocket::SocketError socketError) {
    if (socketError == QAbstractSocket::SocketError::RemoteHostClosedError) {
        qInfo() << "End of transmission";
        return;
    }
    qInfo() << "Received error from socket";
    socket.close();
    if (!ended) {
        r_error(QString("Socket Error: ")
                + QMetaEnum::fromType<QAbstractSocket::SocketError>().key(socketError));
        r_text("This error occured on the client side.");
        r_end();
        ended = true;
    }
}

void GopherRequest::disconnected() {
    qInfo() << "Disconnected";
    socket.close();
    running = false;
    if (!ended) {
        r_end();
        ended = true;
    }
    qInfo() << "Request ended, detected encoding: " << QMetaEnum::fromType<Encoding>().key(enc);
}

void GopherRequest::readyRead()
{
    qInfo() << "Ready to read";
    if (type == "1" || type == "7") readMenu();
    else readText();
}

void GopherRequest::readText() {
    while (socket.canReadLine()) {
        r_text(readLine());
    }
}

void GopherRequest::readMenu() {
    while (socket.canReadLine()) {
        QString line = readLine();
        if (line.length() < 2) continue;
        char type = line.at(0).toLatin1();
        QStringList fields = line.mid(1).split('\t');
        line.clear();

        switch (type) {
        case 'i':
            if (fields.length() >= 2 && fields.at(1) == "TITLE") {
                r_title(fields.at(0));
            } else {
                r_text(fields.at(0));
            }
            break;
        case '3':
            r_error(fields.at(0));
            break;
        case '0':
        case '1':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case '+':
        case 'g':
        case 'I':
        case 'T':
        case 's':
        case 'h':
            if (fields.size() < 4) break;
            r_link(QString(type), fields.at(0), fields.at(2), fields.at(3).toInt(), fields.at(1));
            break;
        default:
            break;
        }
    }
}

GopherRequest::Encoding GopherRequest::responseEncoding() {
    return enc;
}

QString GopherRequest::readLine() {
    QString r;
    QByteArray ba = socket.readLine();
    if (enc == EncAuto) enc = encodingOf(ba);
    if (enc == EncUTF8) r = QString::fromUtf8(ba);
    else r = QString::fromLatin1(ba);
    while (r.length() > 0 && (r.endsWith('\n') || r.endsWith('\r'))) {
        r.chop(1);
    }
    return r;
}
