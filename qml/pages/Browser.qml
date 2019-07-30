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

import fr.almel.gopher 1.0

import "../utils.js" as Utils
import ".."

Page {
    id: page

    allowedOrientations: Model.allowedOrientations

    property alias name: pageHeader.title
    property string host
    property int port
    property string selector
    property string type
    property int encoding: GopherRequest.EncAuto
    property bool showRawBuf
    property bool portraitReflow: Model.getConfig(Model.cfgPortraitReflow) === "true";
    property int historyIndex: 0

    SilicaFlickable {
        id: pageflick
        anchors.fill: parent
        contentHeight: pageColumn.implicitHeight
        clip: true
        VerticalScrollDecorator { flickable: pageflick }

        PullDownMenu {
            MenuItem {
                text: "History"
                onClicked: {
                    pageStack.push("History.qml", { historyIndex: historyIndex })
                }
            }

            MenuItem {
                text: (Model.allowedOrientations == Orientation.All ? "Lock" : "Unlock") + " screen orientation"
                onClicked: {
                    if (Model.allowedOrientations == Orientation.All) {
                        Model.allowedOrientations = orientation;
                    } else {
                        Model.allowedOrientations = Orientation.All;
                    }
                }
            }

            MenuItem {
                text: "Details"
                onClicked: {
                    pageStack.push('Details.qml', { name: name, host: host, port: port, selector: selector, type: type, historyIndex: historyIndex + 1 })
                }
            }
            MenuItem {
                text: "Bookmark this page"
                onClicked: {
                    Model.setBookmark(null, name, host, port, type, selector);
                }
            }
        }

        Column {
            id: pageColumn
            width: parent.width

            PageHeader {
                id: pageHeader
            }

            Item {
                id: searchFieldItem
                width: parent.width
                height: searchField.implicitHeight + Theme.paddingLarge
                visible: type == '7'

                IconButton {
                    id: searchFieldButton
                    anchors.right: parent.right
                    anchors.verticalCenter: searchField.verticalCenter
                    enabled: requestEnded;
                    icon.source: 'image://theme/icon-m-search?'
                            + (pressed
                               ? Theme.highlightColor
                               : Theme.primaryColor)
                    onClicked: search();
                }

                TextField {
                    id: searchField
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: searchFieldButton.left
                    enabled: requestEnded;
                    placeholderText: "Search"
                    labelVisible: false
                    inputMethodHints: Qt.ImhNoAutoUppercase
                    focus: false
                    EnterKey.iconSource: 'image://theme/icon-m-search'
                    EnterKey.onClicked: search();
                }
            }

            Text {
                id: content
                property int sidePadding
                x: sidePadding
                width: parent.width - sidePadding * 1.5
                textFormat: Text.StyledText
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                color: Theme.primaryColor
                linkColor: Theme.highlightColor
                horizontalAlignment: Model.getConfig(Model.cfgReflowTextJustify) === "true" ? Text.AlignJustify : Text.AlignLeft
                onLinkActivated: {
                    var dlink = links[link];
                    print(JSON.stringify(dlink));
                    switch (dlink.type) {
                    case '0':
                    case '1':
                    case '7':
                        if (Model.getConfig(Model.cfgHistoryGoBackIfSelectorExists) === "true") {
                            for (var i = Model.history.count - 1 - historyIndex; i < Model.history.count; ++i) {
                                var entry = Model.history.get(i);
                                if (entry.host === dlink.host && entry.port === dlink.port
                                        && Utils.removeTrailingSlash(entry.selector) === Utils.removeTrailingSlash(dlink.selector))
                                {
                                    pageStack.pop(Model.historyPages[Model.history.count - 1 - i]);
                                    break;
                                }
                            }
                        }
                        dlink.encoding = request.responseEncoding();
                        pageStack.push("Browser.qml", dlink);
                        break;
                    default:
                        pageStack.push("Details.qml", dlink);
                        break;
                    }
                }
            }

            Item { width: 1; height: Theme.paddingLarge }

            BusyIndicator {
                id: busyIndicator
                anchors.horizontalCenter: parent.horizontalCenter
                size: BusyIndicatorSize.Medium;
                running: !requestEnded;
            }
        }
    }

    property var links: []
    property bool requestEnded: true;
    property string cutebuf: ""
    property string rawbuf: ""

    GopherRequest {
        id: request

        onR_title: {
            page.name = title;
            Model.history.setProperty(Model.history.count - 1 - historyIndex, "title", title);
        }

        onR_text: {
            parserWorker.sendMessage({ action: "text", line: line });
        }

        onR_error: {
            parserWorker.sendMessage({ action: "error", line: line });
        }

        onR_link: {
            var prefix;
            var link = {
                type: type,
                host: host,
                port: port,
                selector: selector,
                name: name,
                historyIndex: historyIndex + 1,
            };

            if (type == '9' && Model.getConfig(Model.cfgOpenBinaryAsText) === "true") link.type = "0";

            if (type == '7' && host == page.host) link.encoding = request.responseEncoding();

            var ilink = links.length;
            links[ilink] = link;

            parserWorker.sendMessage({ action: "link", type: type, name: name, ilink: ilink, selector: selector });
        }

        onR_start: {
            content.text = "";
            cutebuf = "";
            rawbuf = "";
            parserWorker.sendMessage({ action: "start", type: type, reflowedTextSize: "6", rawTextPrefixColor: Theme.secondaryColor.toString() });
            requestEnded = false;
            searchFieldButton.enabled = false;
        }

        onR_end: {
            searchFieldButton.enabled = true;
            requestEnded = true;
            parserWorker.sendMessage({ action: "end" });
            if (!pageStack.busy) {
                bufUpdateTimer.stop();
                parserWorker.sendMessage({ action: "render" });
            }
        }
    }

    Component.onCompleted: {
        updateContentAspect();
        var entry = { title: name, type: type, host: host, port: port, selector: selector };
        if (historyIndex > Model.history.count) {
            // This is not supposed to happen, but just in case.
            historyIndex = Model.history.count;
        }
        if (historyIndex == Model.history.count) {
            Model.history.insert(0, entry)
        } else {
            Model.history.set(Model.history.count - 1 - historyIndex, entry);
        }
        Model.historyPages[historyIndex] = page;
        if (type != '7') {
            requestEnded = false;
            request.open(host, port, selector, type, encoding);
        } else {
            searchField.focus = true;
        }
    }

    Component.onDestruction: {
        if (Model.historyPages[historyIndex] === page) {
            Model.historyPages[historyIndex] = false;
        }
    }

    onOrientationChanged: {
        updateContentAspect();
    }

    Connections {
        target: pageStack
        onBusyChanged: {
            if (!pageStack.busy && pageStack.currentPage === page) {
                bufUpdateTimer.start();
            }
        }
    }

    Timer {
        id: bufUpdateTimer
        interval: 2000
        repeat: true
        running: false
        triggeredOnStart: true
        onTriggered: {
            parserWorker.sendMessage({ action: "render" });
            if (requestEnded) bufUpdateTimer.stop();
        }
    }

    function search() {
        searchField.focus = false;
        request.open(host, port, selector + "\t" + searchField.text.trim(), type, encoding);
        requestEnded = false;
        bufUpdateTimer.start();
    }

    function updateContentAspect() {
        var portrait = orientation == Orientation.Portrait || orientation == Orientation.PortraitInverted;
        showRawBuf = !portrait || !portraitReflow

        if (portrait) {
            if (portraitReflow) {
                content.sidePadding = Theme.horizontalPageMargin;
                content.font.pixelSize = parseInt(Model.getConfig(Model.cfgReflowFontSize)) || Model.preferredReflowedFontSize;
                content.lineHeight = 1.0;
            } else {
                content.sidePadding = Theme.paddingSmall;
                content.font.pixelSize = parseInt(Model.getConfig(Model.cfgPortraitRawFontSize)) || Model.preferredPortraitFontSize;
                content.lineHeight = parseFloat(Model.getConfig(Model.cfgRawLineHeight));
            }
        } else {
            content.sidePadding = Theme.horizontalPageMargin;
            content.font.pixelSize = parseInt(Model.getConfig(Model.cfgLandscapeRawFontSize)) || Model.preferredLandscapeFontSize;
            content.lineHeight = parseFloat(Model.getConfig(Model.cfgRawLineHeight));
        }
        content.text = showRawBuf ? rawbuf : cutebuf;
    }

    WorkerScript {
        id: parserWorker
        source: "../parserWorker.js"

        onMessage: {
            if (messageObject.action === "render") {
                cutebuf += messageObject.cutebuf;
                rawbuf += messageObject.rawbuf;
                content.text += (showRawBuf ? rawbuf : cutebuf).substr(content.text.length);
            }
        }
    }
}
