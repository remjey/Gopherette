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

#include "geminicertificatemanager.h"
#include "customnetworkaccessmanager.h"
#include "customnetworkaccessmanagerfactory.h"
#include "requester.h"

#include <QtQuick>

#include <sailfishapp.h>

QNetworkAccessManager *nam;

int main(int argc, char *argv[])
{
    qmlRegisterType<Requester>("fr.almel.gopher", 1, 0, "Requester");
    qmlRegisterType<GeminiCertificateManager>("fr.almel.gopher", 1, 0, "GeminiCertificateManager");

    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    QNetworkAccessManager *onam = view->engine()->networkAccessManager();
    CustomNetworkAccessManagerFactory::proxy = onam->proxy();

    QScopedPointer<CustomNetworkAccessManagerFactory> cnamf(new CustomNetworkAccessManagerFactory());
    view->engine()->setNetworkAccessManagerFactory(cnamf.data());
    nam = cnamf->create();

    GeminiCertificateManager::load();

    view->setSource(SailfishApp::pathTo("qml/harbour-gopherette.qml"));
    view->show();

    return app->exec();
}
