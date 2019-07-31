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

    Text {
        id: referenceTxtReflow
        textFormat: Text.StyledText
        text: "<font size=\"1\"><pre>0----.----1----.----2----.----3----.----4----.----5----.----6----.----7----.---]</pre></font>"
        font.pixelSize: Theme.fontSizeMedium
        opacity: 0
    }

    Text {
        id: referenceTxtRaw
        textFormat: Text.StyledText
        text: "<pre>0----.----1----.----2----.----3----.----4----.----5----.----6----.----7----.---]</pre>"
        font.pixelSize: Theme.fontSizeMedium
        opacity: 0
    }

    property real referenceTxtReflowSize: referenceTxtReflow.font.pixelSize * (Screen.width - Theme.horizontalPageMargin) / referenceTxtReflow.width
    property real referenceTxtRawPortraitSize: referenceTxtRaw.font.pixelSize * (Screen.width - Theme.horizontalPageMargin) / referenceTxtRaw.width
    property real referenceTxtRawLandscapeSize: referenceTxtRaw.font.pixelSize * (Screen.height - Theme.horizontalPageMargin) / referenceTxtRaw.width

    Component.onCompleted: {
        console.log("Screen size: " + Screen.width + "x" + Screen.height + ", pixelRatio: " + Theme.pixelRatio + ", horizontalPageMarin: " + Theme.horizontalPageMargin)
        console.log("Reflow Size: " + referenceTxtReflowSize)
        console.log("Raw Portrait Size: " + referenceTxtRawPortraitSize)
        console.log("Raw Landscape Size: " + referenceTxtRawLandscapeSize)

        referenceTxtReflow.visible = false;
        referenceTxtRaw.visible = false;

        Model.preferredReflowedFontSize =
                Math.floor(
                    Math.min((Screen.width - Theme.horizontalPageMargin) / 35, // Should be 33.59375 but realistic tests prefer 35
                             Theme.fontSizeMedium));
        Model.preferredPortraitFontSize =
                Math.floor(
                    Math.min((Screen.width - Theme.horizontalPageMargin) / 48,
                             Theme.fontSizeLarge));
        Model.preferredLandscapeFontSize =
                Math.floor(
                    Math.min((Screen.height - Theme.horizontalPageMargin) / 48,
                             Theme.fontSizeLarge));
    }
}

