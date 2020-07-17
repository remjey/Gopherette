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

#include "requester.h"
#include "harbour-gopherette.h"
#include "geminicachedrequestdata.h"

#include <QtDebug>
#include <QUrl>
#include <QMetaEnum>
#include <QRegExp>
#include <QRegularExpression>

Requester::Encoding encodingOf(const QByteArray& ba)
{
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
                return Requester::EncLatin1;
            } else {
                --utf8_rem;
            }
        } else if ((c & 0x80) == 0) {
            // 0x0xxxxxxx (ASCII)
            if (utf8_rem > 0) {
                // This is invalid UTF8, switch to Latin1
                return Requester::EncLatin1;
            } else {
                // Not sure
            }
        } else {
            // Not ASCIII, not correct UTF8
            // (supposedly 0x11111xxx and invalid UTF8
            return Requester::EncLatin1;
        }
    }
    if (has_utf8) {
        if (utf8_rem == 0) return Requester::EncUTF8;
        else return Requester::EncLatin1; // Invalid UTF8
    }
    // Only ASCII text was encountered
    return Requester::EncAuto;
}

Requester::Requester(QObject *parent) : QObject(parent), reply(nullptr)
{
    /*
    connect(&socket, &QIODevice::readyRead, this, &Requester::readyRead);
    connect(&socket, &QAbstractSocket::connected, this, &Requester::connected);
    connect(&socket, static_cast<void(QAbstractSocket::*)(QAbstractSocket::SocketError)>(&QAbstractSocket::error), this, &Requester::error);
    connect(&socket, &QAbstractSocket::disconnected, this, &Requester::disconnected);
    */
}

Requester::~Requester()
{
    if (reply) reply->deleteLater();
}

void Requester::open(QString host, quint16 port, QString selector, QString query, QString type, Encoding enc)
{
    QUrl url_dst;

    if (type == "gemini") {
        if (selector.length() == 0 || selector.at(0) != '/') selector.insert(0, '/');

        url_dst.setScheme("gemini");
        url_dst.setHost(host);
        if (port) url_dst.setPort(port);
        url_dst.setPath(selector);
        if (!query.isEmpty()) url_dst.setQuery(query, QUrl::DecodedMode);

    } else {
        url_dst.setScheme("gopher");
        url_dst.setHost(host);
        if (port) url_dst.setPort(port);
        url_dst.setPath("/" + type + selector);
        if (!query.isEmpty()) url_dst.setQuery(query, QUrl::DecodedMode);

    }

    open(url_dst, enc);
}

void Requester::open(QUrl url_arg, Encoding enc)
{
    if (reply) return;

    this->url = url_arg;
    if (url.scheme() == "gemini") {
        this->enc = EncUTF8;
        this->type = "gemini";
    } else {
        this->enc = enc;
        if (url.path().length() < 2) {
            this->type = "1"; // Menu
        } else {
            this->type = url.path().at(1);
        }
    }

    gemini_title_sent = false;
    gemini_pre_toggle = false;
    redirection.clear();
    reply = dynamic_cast<CustomReply*>(nam->get(QNetworkRequest(url)));

    connect(reply, &QIODevice::readyRead, this, &Requester::readyRead);
    connect(reply, &QNetworkReply::finished, this, &Requester::disconnected);
    connect(reply, static_cast<void (QNetworkReply::*)(QNetworkReply::NetworkError)>(&QNetworkReply::error),
            this, &Requester::error);
    connect(reply, &QNetworkReply::metaDataChanged, this, &Requester::metaDataChanged);
    connect(reply, &QNetworkReply::redirected, this, &Requester::redirected);

    connect(reply, &CustomReply::geminiCertificateUnknown, this, &Requester::onGeminiCertificateUnknown);
    connect(reply, &CustomReply::geminiCertificateChanged, this, &Requester::onGeminiCertificateChanged);

    if (enc == EncUTF8) reply->setGopherQueryUTF8(true);

    r_start(url.scheme());
    qInfo() << "Gopher/Gemini request: " << url;
}

void Requester::error(QNetworkReply::NetworkError code)
{
    auto err_str = QMetaEnum::fromType<QNetworkReply::NetworkError>().valueToKey(code);
    if (err_str == nullptr) err_str = "unnknown error";

    qInfo() << "Received error from socket: " << err_str << "(" << code << ")";

    r_error(QString("Socket Error: ") + err_str
            + " (" + QString::number(code) + ")");
    r_text("This error message was generated on the client side.");
    r_end();
}

void Requester::metaDataChanged()
{
    if (type != "gemini") return;

    QString meta = reply->rawHeader("x-gemini-meta");

    int status_value = reply->rawHeader("x-gemini-status").toInt();
    auto statusMetaEnum = QMetaEnum::fromType<GeminiStatus>();
    const char *status_name = statusMetaEnum.valueToKey(status_value);
    if (!status_name) {
        status_value = 10 * (status_value / 10);
        status_name = statusMetaEnum.valueToKey(status_value);
    }
    if (!status_name) {
        status_value = GeminiInvalidStatus;
        status_name = statusMetaEnum.valueToKey(status_value);
    }

    qInfo("Gemini status: %s, translated to %d (%s)", reply->rawHeader("x-gemini-status").data(), status_value, status_name);
    qInfo() << "Gemini meta: " << meta;

    if (status_value / 10 == 2) {
        QStringList items = meta.split(';', QString::SkipEmptyParts);
        gemini_content_type = items.at(0).trimmed();
        if (gemini_content_type.startsWith("text/")) {
            if (gemini_content_type == "text/gemini") {
                gemini_parse_level = GeminiTextRich;
            } else {
                gemini_parse_level = GeminiTextPlain;
            }
        } else {
            gemini_parse_level = GeminiNonText;
            if (!gemini_content_type.startsWith("image/")) {
                r_error("Unsupported file-type: " + gemini_content_type);
                r_text("This error message was generated on the client side.");
                reply->abort();
            }
        }

        for (int i = 1; i < items.length(); ++i) {
            QString param = items.at(i).trimmed();
            int pos = param.indexOf('=');
            QString property, value;
            if (pos == -1) {
                property = param.toLower();
            } else {
                property = param.mid(0, pos);
                value = param.mid(pos + 1);
            }

            if (property == "charset") {
                value = value.toLower();
                if (value == "utf8" || value == "utf-8") {
                    gemini_charset = "utf-8";
                    enc = EncUTF8;
                } else {
                    gemini_charset = "latin1";
                    enc = EncLatin1;
                }
            }
        }
    }

    r_gemini_header(static_cast<GeminiStatus>(status_value), meta);

    if (gemini_parse_level == GeminiTextPlain) {
        gemini_pre_toggle = true;
        r_gemini_pre_start("");
    }
}

void Requester::redirected(const QUrl &r)
{
    redirection = url.resolved(r);
}

void Requester::onGeminiCertificateUnknown(QString fp, bool cn_ok, QString cns)
{
    r_gemini_certificate_unknown(fp, cn_ok, cns);
}

void Requester::onGeminiCertificateChanged(QString fp, bool cn_ok, QString cns)
{
    r_gemini_certificate_changed(fp, cn_ok, cns);
}

void Requester::reopen(bool accept_certificate)
{
    open(url, EncAuto);
    if (accept_certificate) reply->acceptCertificate();
}

void Requester::disconnected()
{
    qInfo() << "Disconnected, bytes remaining " << (reply ? reply->bytesAvailable() : 0);
    readyRead();
    if (!redirection.isEmpty() && redirection_counter == 5) {
        r_error("Too many redirections.");
        r_error("Last aborted redirection: " + redirection.toString());
        r_text("This error message was generated on the client side.");
    }
    r_end();
    reply->deleteLater();
    reply = nullptr;

    qInfo() << "Request ended, encoding: " << QMetaEnum::fromType<Encoding>().key(enc);
    if (!redirection.isEmpty()) {
        if (redirection_counter == 5) {
            qInfo() << "Too many redirections.";
            redirection_counter = 0;
        } else {
            qInfo() << "Redirected to: " << redirection;
            redirection_counter++;
            open(redirection, enc);
        }
    } else {
        redirection_counter = 0;
        if (gemini_parse_level == GeminiNonText) {
            quint64 id = GeminiCachedRequestData::steal(gemini_nontext_buffer);
            r_gemini_data_link("geminicache:///" + QString::number(id), gemini_content_type);
        }
    }
}

void Requester::readyRead()
{
    if (type == "1" || type == "7") {
        readMenu();
    } else if (type == "gemini") {
        if (gemini_parse_level == GeminiNonText)
            readGeminiNonText();
        else
            readGemini();
    } else {
        readText();
    }
}

static QRegularExpression gemini_link_match("^=>\\s*(\\S+)(\\s+(.*))?");

void Requester::readGemini()
{
    while (reply->canReadLine()) {
        QString line = readLine();
        if (gemini_pre_toggle) {
            if (line.startsWith("```") && gemini_parse_level == GeminiTextRich) {
                gemini_pre_toggle = false;
                r_gemini_pre_stop();
            } else {
                r_text(line);
            }
        } else if (line.startsWith("```")) {
            gemini_pre_toggle = true;
            r_gemini_pre_start(line.mid(3).trimmed());

        } else if (line.startsWith("###")) {
            r_gemini_section(3, line.mid(3).trimmed());
        } else if (line.startsWith("##")) {
            r_gemini_section(2, line.mid(2).trimmed());
        } else if (line.startsWith("#")) {
            r_gemini_section(1, line.mid(1).trimmed());
            if (!gemini_title_sent) {
                r_title(line.mid(1).trimmed());
                gemini_title_sent = true;
            }

        } else if (line.startsWith("* ")) {
            r_gemini_list(line.mid(2));

        } else if (line.startsWith("=>")) {
            auto link_match = gemini_link_match.match(line.trimmed());
            if (!link_match.hasMatch()) {
                r_text(line);
                continue;
            }

            QUrl link_url(link_match.captured(1));
            if (!link_url.isValid()) {
                r_text(line);
                continue;
            }

            QString text;
            if (link_match.capturedLength(3) > 0)
                text = link_match.captured(3);
            else
                text = link_url.toString();

            link_url = url.resolved(link_url);

            if (link_url.scheme() == "gemini") {
                r_link("gemini", text, link_url.host(), static_cast<uint16_t>(link_url.port(1965)), link_url.path(), link_url.query(QUrl::FullyDecoded));
            } else if (link_url.scheme() == "gopher") {
                QString type = "1";
                if (link_url.path().length() >= 2) type = link_url.path().mid(1, 1);
                r_link(type, text, link_url.host(), static_cast<uint16_t>(link_url.port(70)), link_url.path().mid(2), "");
            } else {
                r_link("h", text, "", 0, "URL:" + link_url.toString(), "");
            }
        } else {
            r_text(line);
        }
    }
}

void Requester::readGeminiNonText() {
    gemini_nontext_buffer.append(reply->readAll());
}

void Requester::readText() {
    while (reply->canReadLine()) {
        r_text(readLine());
    }
}

void Requester::readMenu() {
    while (reply->canReadLine()) {
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
            r_link(QString(type), fields.at(0), fields.at(2), static_cast<uint16_t>(fields.at(3).toInt()), fields.at(1), "");
            break;
        default:
            break;
        }
    }
}

Requester::Encoding Requester::responseEncoding() {
    return enc;
}

void Requester::acceptCertificate()
{
    qInfo("Certificate accepted");
    if (reply) {
        reply->acceptCertificate();
    } else {
        reopen(true);
    }
}

void Requester::abort()
{
    qInfo("Certificate refused");
    if (reply) reply->abort();
}

QString Requester::readLine() {
    QString r;
    QByteArray ba = reply->readLine();
    if (enc == EncAuto) enc = encodingOf(ba);
    if (enc == EncUTF8) r = QString::fromUtf8(ba);
    else r = QString::fromLatin1(ba);
    while (r.length() > 0 && (r.endsWith('\n') || r.endsWith('\r'))) {
        r.chop(1);
    }
    return r;
}
