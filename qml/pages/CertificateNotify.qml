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
import ".."

Dialog {

    acceptDestinationAction: PageStackAction.Pop
    allowedOrientations: Model.allowedOrientations

    property string server;
    property int port;
    property string fp;
    property bool first;
    property bool cn_ok;
    property string cns;
    property var requester;

    onAccepted: {
        requester.acceptCertificate();
    }

    onRejected: {
        requester.abort();
    }

    DialogHeader { }

    Column {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - Theme.horizontalPageMargin * 2
        x: Theme.horizontalPageMargin
        spacing: Theme.paddingLarge

        Label {
            text: first ? "This server has never been visited before." : "The certificate of this server has changed."
            width: parent.width
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.highlightColor
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
        }

        Grid {
            id: grid
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 2
            columnSpacing: Theme.paddingMedium

            Label {
                text: "Server"
                color: Theme.secondaryHighlightColor
            }

            Label {
                text: server
                color: Theme.highlightColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width: 2 * content.width / 3
            }

            Label {
                text: "Port"
                color: Theme.secondaryHighlightColor
            }


            Label {
                text: port
                color: Theme.highlightColor
            }
/*
            Label {
                text: "CN"
                color: Theme.secondaryHighlightColor
            }

            Label {
                text: cn_ok ? "Present" : "Absent"
                color: cn_ok ? Theme.highlightColor : "red"
            }

            Label {
                text: "CN List"
                color: Theme.secondaryHighlightColor
            }

            Label {
                text: cns
                color: Theme.highlightColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width: 2 * content.width / 3
            }
*/
            Label {
                text: "Hash"
                color: Theme.secondaryHighlightColor
            }

            Label {
                text: fp.replace(/..(?=.)/g, function (m) { return m + ":"; })
                color: Theme.highlightColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width: 2 * content.width / 3
            }
        }
    }
}
