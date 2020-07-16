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

#include "geminicertificatemanager.h"

#include <QStandardPaths>
#include <QDebug>
#include <QDir>
#include <QByteArray>

static const char *server_certificates_dir_name = "certificates/servers";

QDir GeminiCertificateManager::server_certificates_dir;

QMap<QString, GeminiCertificateManager::ServerCertificate> GeminiCertificateManager::server_certificates;

GeminiCertificateManager::GeminiCertificateManager(QObject *parent)
    : QObject(parent)
{

}

GeminiCertificateManager::~GeminiCertificateManager()
{

}

void GeminiCertificateManager::load()
{
    QDir path(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));
    path.mkpath(server_certificates_dir_name);
    server_certificates_dir = path.absoluteFilePath(server_certificates_dir_name);

    for (auto &entry : server_certificates_dir.entryList(QDir::Files)) {
        auto cert = QSslCertificate::fromPath(server_certificates_dir.absoluteFilePath(entry), QSsl::Der).at(0);
        auto &ss = server_certificates[entry];
        ss.cert = cert;
        ss.fp = fingerprintFor(cert);
    }
}

GeminiCertificateManager::ServerCertificateResponse GeminiCertificateManager::check_server(
        const QString &server, int port, const QSslCertificate &cert, QString *out_fingerprint)
{
    QString fp = fingerprintFor(cert);
    if (out_fingerprint) *out_fingerprint = fp;

    auto sc_it = server_certificates.find(keyFor(server, port));
    if (sc_it == server_certificates.end()) {
        return ServerCertificateUnknown;
    }

    if (sc_it.value().fp == fp) {
        return ServerCertificateOK;
    }

    return ServerCertificateChanged;
}

void GeminiCertificateManager::update_server(const QString &server, int port, const QSslCertificate &cert)
{
    auto k = keyFor(server, port);
    auto &ss = server_certificates[k];
    ss.fp = fingerprintFor(cert);
    ss.cert = cert;

    QFile f(server_certificates_dir.absoluteFilePath(k));
    f.open(QFile::WriteOnly);
    f.write(cert.toDer());
    f.close();
}

QString GeminiCertificateManager::fingerprintFor(const QSslCertificate &cert)
{
    return cert.digest(QCryptographicHash::Sha256).toHex();
}

QString GeminiCertificateManager::keyFor(const QString &server, int port)
{
    return server + ":" + QString::number(port);
}
