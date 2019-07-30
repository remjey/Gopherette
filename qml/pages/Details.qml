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

import "../utils.js" as Utils
import ".."

Page {
    id: page
    allowedOrientations: Model.allowedOrientations

    property alias name: pageHeader.title
    property alias host: thost.text
    property alias port: tport.text
    property string selector
    property string type
    property int historyIndex: 0

    property string url: "gopher://" + host + ":" + port + "/" + type + encodeURI(selector)
    property var _webURL: type == "h" && Utils.isWebURL(selector)

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        VerticalScrollDecorator {}

        Column {
            id: content
            width: parent.width

            PageHeader {
                id: pageHeader
            }


            // TODO when fields contain large contents
            Grid {
                id: grid
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                columns: 2
                columnSpacing: Theme.paddingSmall

                Label {
                    text: "Type"
                    color: Theme.secondaryHighlightColor
                }

                Label {
                    id: ttype
                    color: Theme.highlightColor
                    text: {
                        switch (type) {
                        case '0': return 'Text file';
                        case '1': return 'Gopher submenu';
                        case '2': return 'CCSO Nameserver';
                        case '4': return 'BinHex-encoded file';
                        case '5': return 'DOS file';
                        case '6': return 'uuencoded file';
                        case '7': return 'Gopher full-text search';
                        case '8': return 'Telnet';
                        case '9': return 'Binary file';
                        case '+': return 'Mirror or alternate server';
                        case 'g': return 'GIF file';
                        case 'I': return 'Image file';
                        case 'T': return 'Telnet 3270';
                        case 'h': return _webURL ? 'URL' : 'HTML file';
                        case 's': return 'Sound file';
                        default: return 'Unknown type: ' + type;
                        }
                    }
                }

                Label {
                    text: "Server"
                    color: Theme.secondaryHighlightColor
                    visible: !_webURL
                }

                Label {
                    id: thost
                    color: Theme.highlightColor
                    visible: !_webURL
                }
                Label {
                    text: "Port"
                    color: Theme.secondaryHighlightColor
                    visible: !_webURL
                }
                Label {
                    id: tport
                    color: Theme.highlightColor
                    visible: !_webURL
                }
                Label {
                    text: {
                        if (_webURL) return 'URL';
                        switch (type) {
                        case '8':
                        case 'T':
                            return "User";
                        default: return "Selector";
                        }
                    }
                    color: Theme.secondaryHighlightColor
                }
                Label {
                    id: tselector
                    width: grid.width - x
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    color: Theme.highlightColor
                    text: _webURL ? _webURL : selector;
                }
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: _webURL
                text: "Open in external browser"
                onClicked: Qt.openUrlExternally(_webURL);
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: type == "9"
                text: "View as text"
                onClicked: {
                    var dlink = {
                        type: "0",
                        host: host,
                        port: port,
                        selector: selector,
                        name: name,
                        historyIndex: historyIndex,
                    };
                    pageStack.replace("Browser.qml", dlink);
                }

            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Copy URL to clipboard"
                onClicked: Clipboard.text = _webURL || url;
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                visible: type == "9"
                text: "This is a dangerous option, Gopherette may misbehave if the content being displayed isn’t text. Only use this function if you know what you are doing."
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                horizontalAlignment: Text.AlignHCenter
            }

            MouseArea {
                width: parent.width
                height: Math.max(imageBusy.height, pic.height)

                BusyIndicator {
                    id: imageBusy
                    size: BusyIndicatorSize.Medium
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                onWidthChanged: pic.updateSize()

                Image {
                    id: pic
                    visible: false
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
                        } else if (status == Image.Error) {
                            imageBusy.running = false;
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (type == "I" || type == "g") {
            imageBusy.running = true;
            pic.visible = true;
            pic.source = url;
        }
    }

}
