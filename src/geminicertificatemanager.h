/* This file is part of Gopherette, the SailfishOS Gopher-space browser.
 * Copyright (C) 2020 - Jérémy Farnaud
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

#ifndef GEMINICERTIFICATES_H
#define GEMINICERTIFICATES_H

#include <QMap>
#include <QMutex>
#include <QObject>
#include <QSslCertificate>
#include <QSslKey>
#include <QDir>

class GeminiCertificateManager : public QObject
{
public:
    GeminiCertificateManager(QObject *parent = nullptr);
    ~GeminiCertificateManager();

    enum ServerCertificateResponse {
        ServerCertificateUnknown, ServerCertificateOK, ServerCertificateChanged
    };
    Q_ENUM(ServerCertificateResponse)

    ServerCertificateResponse check_server(const QString &server, int port, const QSslCertificate &cert, QString *out_fingerprint);
    void update_server(const QString &server, int port, const QSslCertificate &cert);

    static void load();

private:
    struct ServerCertificate {
        QString fp;
        QSslCertificate cert;
    };

    static QDir server_certificates_dir;

    static QMap<QString, ServerCertificate> server_certificates;

    //QMap<QString, quint64> local_certificate_mappings;

    //QMap<quint64, QSslCertificate> local_certificates;

    static QString fingerprintFor(const QSslCertificate &cert);
    static QString keyFor(const QString &server, int port);
};

#endif // GEMINICERTIFICATES_H
