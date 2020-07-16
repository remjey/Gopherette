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
