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
