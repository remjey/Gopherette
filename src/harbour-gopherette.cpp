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

#include "harbour-gopherette.h"

#include "customnetworkaccessmanager.h"
#include "requester.h"

#include <QtQuick>

#include <sailfishapp.h>

QNetworkAccessManager *nam;

static QNetworkProxy proxy;

class CustomNetworkAccessManagerFactory : public QQmlNetworkAccessManagerFactory
{
public:
    ~CustomNetworkAccessManagerFactory() {}

    QNetworkAccessManager *create(QObject *parent = nullptr);
};

QNetworkAccessManager *CustomNetworkAccessManagerFactory::create(QObject *parent)
{
    CustomNetworkAccessManager *r = new CustomNetworkAccessManager(parent);
    r->setProxy(proxy);
    return r;
}

static CustomNetworkAccessManagerFactory *cnamf;

int main(int argc, char *argv[])
{
    qmlRegisterType<Requester>("fr.almel.gopher", 1, 0, "Requester");

    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    QNetworkAccessManager *onam = view->engine()->networkAccessManager();
    proxy = onam->proxy();

    cnamf = new CustomNetworkAccessManagerFactory();
    nam = cnamf->create();
    view->engine()->setNetworkAccessManagerFactory(cnamf);

    view->setSource(SailfishApp::pathTo("qml/harbour-gopherette.qml"));
    view->show();

    return app->exec();
}
