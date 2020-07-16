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

#include "customnetworkaccessmanager.h"
#include "customnetworkaccessmanagerfactory.h"

QNetworkProxy CustomNetworkAccessManagerFactory::proxy;

CustomNetworkAccessManagerFactory::~CustomNetworkAccessManagerFactory()
{

}

QNetworkAccessManager *CustomNetworkAccessManagerFactory::create(QObject *parent)
{
    CustomNetworkAccessManager *r = new CustomNetworkAccessManager(parent);
    r->setProxy(proxy);
    return r;
}
