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

QtObject {

    property int myDepth: -1

    property var connections: Connections {
        target: pageStack
        onBusyChanged: deferTimer.start();
    }

    property var deferTimer : Timer {
        interval: 0
        repeat: false
        onTriggered: {
            if (myDepth == -1) {
                myDepth = pageStack.depth
            }
            if (pageStack.busy) {
                changing(pageStack.depth === myDepth);
            } else {
                changed(pageStack.depth === myDepth);
            }
        }
    }

    signal changing(bool toMe);

    signal changed(bool toMe);
}
