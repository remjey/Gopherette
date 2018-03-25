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
#include "gopherrequest.h"

#include <QtQuick>

#include <sailfishapp.h>

QNetworkAccessManager *nam;

namespace {
    QNetworkProxy proxy;
}

class CustomNetworkAccessManagerFactory : public QQmlNetworkAccessManagerFactory
{
public:
    virtual QNetworkAccessManager *create(QObject *parent = nullptr) {
        CustomNetworkAccessManager *r = new CustomNetworkAccessManager(parent);
        r->setProxy(proxy);
        return r;
    }

};

namespace {
    CustomNetworkAccessManagerFactory *namf;
}

int main(int argc, char *argv[]) {
    qmlRegisterType<GopherRequest>("fr.almel.gopher", 1, 0, "GopherRequest");

    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    QNetworkAccessManager *onam = view->engine()->networkAccessManager();
    proxy = onam->proxy();

    namf = new CustomNetworkAccessManagerFactory();
    nam = namf->create();
    view->engine()->setNetworkAccessManagerFactory(namf);

    view->setSource(SailfishApp::pathTo("qml/harbour-gopherette.qml"));
    view->show();

    return app->exec();
}
