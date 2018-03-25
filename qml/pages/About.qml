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

import "../components"

Page {
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge
        VerticalScrollDecorator { }
        Column {
            id: content
            width: parent.width

            PageHeader {
                title: qsTr("About Gopherette")
            }

            Column {
                width: parent.width
                spacing: Theme.paddingLarge

                Label {
                    width: parent.width - Theme.horizontalPageMargin * 2
                    x: Theme.horizontalPageMargin
                    color: Theme.highlightColor
                    text: qsTr("Gopherette is Free Software developped by Jérémy Farnaud and released under the GNU GPLv3 license.")
                    wrapMode: Text.WordWrap
                }
            }

            SectionHeader {
                text: qsTr("Links")
            }

            MenuButton {
                imageSource: "image://theme/icon-m-link"
                label: qsTr("Gopherette GitHub Repository")
                subLabel: qsTr("For source code, bug reports and feature requests.")
                onClicked: Qt.openUrlExternally("https://github.com/remjey/Gopherette")
            }

            MenuButton {
                imageSource: "image://theme/icon-m-mail"
                label: qsTr("Contact %1").arg("Jérémy Farnaud")
                onClicked: Qt.openUrlExternally("mailto:jf@almel.fr")
            }

            SectionHeader {
                text: qsTr("License")
            }

            MenuButton {
                imageSource: "image://theme/icon-m-document"
                label: "GNU GPLv3"
                onClicked: pageStack.push(licensePage, { title: label, source: Qt.resolvedUrl("../assets/gpl-3.0-standalone.html") })
            }
        }
    }

    Component {
        id: licensePage
        Page {
            id: licensePageRoot
            property string title
            property string source
            SilicaFlickable {
                anchors.fill: parent
                contentHeight: content.height + Theme.paddingLarge
                VerticalScrollDecorator {}
                Column {
                    id: content
                    width: parent.width
                    PageHeader {
                        title: licensePageRoot.title
                    }
                    TextEdit {
                        id: textDisplay
                        width: parent.width - Theme.horizontalPageMargin * 2
                        height: implicitHeight
                        x: Theme.horizontalPageMargin
                        readOnly: true
                        textFormat: TextEdit.AutoText
                        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.highlightColor
                    }
                }
            }
            Component.onCompleted: {
                var xhr = new XMLHttpRequest();
                xhr.onreadystatechange = function () {
                    if (xhr.readyState == 4) {
                        textDisplay.text = xhr.responseText
                    }
                }
                xhr.open("get", source);
                xhr.send()
            }
        }
    }
}

