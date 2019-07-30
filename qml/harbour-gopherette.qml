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

import QtQuick 2.0
import Sailfish.Silica 1.0
import "."

ApplicationWindow
{
    initialPage: Qt.resolvedUrl("pages/Bookmarks.qml")
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: Model.allowedOrientations


    Component.onCompleted: {
        Model.preferredReflowedFontSize =
                Math.round(
                    Math.min((Math.min(Screen.width, Screen.height) - Theme.horizontalPageMargin) / 36,
                             Theme.fontSizeMedium));
        Model.preferredPortraitFontSize =
                Math.round(
                    Math.min((Math.min(Screen.width, Screen.height) - Theme.horizontalPageMargin) / 49,
                             Theme.fontSizeLarge));
        Model.preferredLandscapeFontSize =
                Math.round(
                    Math.min((Math.max(Screen.width, Screen.height) - Theme.horizontalPageMargin) / 49,
                             Theme.fontSizeLarge));
    }
}

