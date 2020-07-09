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

#include "customnetworkaccessmanager.h"
#include "gopherreply.h"

#include <QNetworkRequest>

CustomNetworkAccessManager::CustomNetworkAccessManager(QObject *parent)
    : QNetworkAccessManager(parent)
{

}

QNetworkReply *CustomNetworkAccessManager::createRequest(QNetworkAccessManager::Operation op, const QNetworkRequest &request, QIODevice *outgoingData)
{
    if (request.url().scheme() == "gopher" || request.url().scheme() == "gemini") {
        if (op != QNetworkAccessManager::Operation::GetOperation) return nullptr;
        GopherReply *r = new GopherReply(request, this);
        r->open(QIODevice::ReadWrite);
        return r;

    } else {
        return QNetworkAccessManager::createRequest(op, request, outgoingData);
    }
}

QStringList CustomNetworkAccessManager::supportedSchemesImplementation() const
{
    QStringList r = QNetworkAccessManager::supportedSchemesImplementation();
    r.append("gopher");
    return r;
}
