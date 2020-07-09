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
import ".."

Dialog {
    id: root
    acceptDestinationAction: PageStackAction.Pop
    allowedOrientations: Model.allowedOrientations

    property var idx: null
    property var id: null

    onAccepted: {
        Model.setBookmark(
                    id, tname.text.trim(), thost.text.trim(), parseInt(tport.text.trim()),
                    protocol.currentIndex === 0 ? ttype.get() : "gemini" ,
                    tselector.text.trim());
    }

    canAccept: {
        return true;
    }

    Component.onCompleted: {
        if (idx !== null) {
            var r = Model.bookmarks.get(idx);
            id = r.id;
            tname.text = r.name;
            thost.text = r.host;
            tport.text = r.port;
            if (r.type === "gemini") {
                protocol.currentIndex = 1;
            } else {
                ttype.set(r.type);
            }
            tselector.text = r.selector;
        }
    }

//            grem = Clipboard.text.match(/^gopher:\/\/([\w.-]+)(:\d+)?\/(([0157hgIs])(.*))?$/i);

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        VerticalScrollDecorator { }

        Column {
            id: content
            width: parent.width

            DialogHeader {
                id: header
                title: idx === null ? "New Bookmark" : "Edit Bookmark"
            }

            TextField {
                id: tname
                width: parent.width
                placeholderText: "Bookmark name"
                label: placeholderText
                inputMethodHints: Qt.ImhNoPredictiveText
                focus: true
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: thost.focus = true;
            }

            ComboBox {
                id: protocol
                label: "Protocol: "
                width: parent.width
                currentIndex: 0
                menu: ContextMenu {
                    MenuItem { text: "Gopher" }
                    MenuItem { text: "Gemini" }
                }
                onCurrentIndexChanged: {
                    if (currentIndex == 0) tport.text = "70";
                    else if (currentIndex == 1) tport.text = "1965";
                }
            }

            TextField {
                id: thost
                width: parent.width
                placeholderText: "Host name"
                label: placeholderText
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: tport.focus = true;
            }

            TextField {
                id: tport
                width: parent.width
                placeholderText: "Port"
                label: placeholderText
                inputMethodHints: Qt.ImhDigitsOnly
                text: "70"
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: tselector.focus = true
            }

            ComboBox {
                id: ttype
                width: parent.width
                label: "Type"
                currentIndex: 0
                visible: protocol.currentIndex == 0

                menu: ContextMenu {
                    MenuItem { text: "Menu" }
                    MenuItem { text: "Text file" }
                    MenuItem { text: "Full-text search" }
                    MenuItem { text: "HTML file" }
                    MenuItem {
                        text: "Other";
                        visible: (idx !== null && ttype._overrideType != "")
                    }
                }

                property var _types: [ "1", "0", "7", "h", "" ];
                property string _overrideType: "";

                function get() {
                    var tt = _types[currentIndex];
                    if (tt === "") return _overrideType;
                    else return tt;
                }

                function set(v) {
                    var idx = _types.indexOf(v);
                    if (idx >= 0) currentIndex = idx;
                    else {
                        _overrideType = v;
                        currentIndex = _types.indexOf("");
                    }
                }
            }

            TextField {
                id: tselector
                width: parent.width
                placeholderText: "Selector / Path"
                label: placeholderText
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: accept();
            }
        }
    }
}
