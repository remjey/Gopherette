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

import QtQuick 2.0
import Sailfish.Silica 1.0

MouseArea {
    width: parent.width
    height: Math.max(imageBusy.height, pic.height)

    function load(url) {
        console.log(url)
        imageBusy.running = true;
        pic.source = url;
        loaded = false;
    }

    function unload() {
        imageBusy.running = false;
        pic.source = "";
        loaded = false;
    }

    property bool loaded: loaded;

    BusyIndicator {
        id: imageBusy
        size: BusyIndicatorSize.Medium
        anchors.horizontalCenter: parent.horizontalCenter
    }

    onWidthChanged: pic.updateSize()

    Image {
        id: pic
        opacity: 0
        Behavior on opacity {
            NumberAnimation { duration: 250 }
        }

        onStatusChanged: updateSize();

        function updateSize() {
            if (status == Image.Ready) {
                width = parent.width;
                height = implicitHeight * width / implicitWidth;
                imageBusy.running = false;
                opacity = 1;
                loaded = true;
            } else if (status == Image.Error) {
                imageBusy.running = false;
            }
        }
    }
}
