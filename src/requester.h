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
#include <QNetworkReply>

class Requester : public QObject
{
    Q_OBJECT

public:
    explicit Requester(QObject *parent = nullptr);
    ~Requester();

    enum Encoding { EncAuto = 0, EncLatin1 = 1, EncUTF8 = 2 };
    Q_ENUM(Encoding)

    enum GeminiStatus {
        GeminiInvalidStatus = 0,

        GeminiInput = 10,
        GeminiInputSensitive = 11,

        GeminiSuccess = 20,

        GeminiRedirect = 30,
        GeminiRedirectPermanent = 31,

        GeminiFailure = 40,
        GeminiServerUnavailable = 41,
        GeminiCGIError = 42,
        GeminiProxyError = 43,
        GeminiSlowDown = 44,

        GeminiFailurePermanent = 50,
        GeminiNotFound = 51,
        GeminiGone = 52,
        GeminiProxyRequestRefused = 53,
        GeminiBadRequest = 54,

        GeminiClientCertificateRequired = 60,
        GeminiCertificateNotAuthorized = 61,
        GeminiCertificateNotValid = 62,
    };
    Q_ENUM(GeminiStatus)


    enum GeminiParseLevel { GeminiNonText, GeminiTextRich, GeminiTextPlain };
    Q_ENUM(GeminiParseLevel)

    Q_INVOKABLE
    void open(QString host, quint16 port, QString selector = "", QString query = "", QString type = "1", Encoding enc = EncAuto);
    void open(QUrl url, Encoding enc = EncAuto);

    Q_INVOKABLE
    Encoding responseEncoding();

signals:
    void r_start(QString protocol);
    void r_text(QString line);
    void r_title(QString title);
    void r_link(QString type, QString name, QString host, quint16 port, QString selector, QString query);
    void r_error(QString line);
    void r_end();

    void r_gemini_header(GeminiStatus status, QString meta);
    void r_gemini_section(int level, QString text);
    void r_gemini_pre_start(QString alt_text);
    void r_gemini_pre_stop();
    void r_gemini_list(QString text);
    void r_gemini_data_link(QUrl url, QString content_type);

public slots:

protected slots:
    void readyRead();
    void error(QNetworkReply::NetworkError code);
    void disconnected();
    void metaDataChanged();
    void redirected(const QUrl &url);

private:
    QString type;
    Encoding enc;
    QUrl url, redirection;

    QString gemini_content_type;
    QString gemini_charset;
    GeminiParseLevel gemini_parse_level;
    QByteArray gemini_nontext_buffer;

    bool gemini_title_sent;
    bool gemini_pre_toggle;

    QNetworkReply *reply;

    void fillGeminiRelative(QUrl &url_arg);

    void readMenu();
    void readText();
    void readGemini();
    void readGeminiNonText();
    void close();
    QString readLine();
};

#endif // GOPHERREQUEST_H
