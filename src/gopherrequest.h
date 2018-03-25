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

#ifndef GOPHERREQUEST_H
#define GOPHERREQUEST_H

#include <QObject>
#include <QTcpSocket>

class GopherRequest : public QObject
{
    Q_OBJECT

public:
    explicit GopherRequest(QObject *parent = 0);

    enum Encoding { EncAuto, EncLatin1, EncUTF8 };
    Q_ENUM(Encoding)

    Q_INVOKABLE
    void open(QString host, quint16 port, QString selector = "", QString type = "1", Encoding enc = EncAuto);

    Q_INVOKABLE
    Encoding responseEncoding();

signals:
    void r_start();
    void r_text(QString line);
    void r_title(QString title);
    void r_link(QString type, QString name, QString host, quint16 port, QString selector);
    void r_error(QString line);
    void r_end();

public slots:

protected slots:
    void readyRead();
    void connected();
    void error(QAbstractSocket::SocketError socketError);
    void disconnected();

private:
    QString host;
    quint16 port;
    QString selector;
    QString type;
    Encoding enc;

    bool running;
    bool ended;
    QTcpSocket socket;

    void readMenu();
    void readText();
    void close();
    QString readLine();
};

#endif // GOPHERREQUEST_H
