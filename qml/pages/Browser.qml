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
import "../components"
import ".."

Page {
    id: page

    allowedOrientations: Model.allowedOrientations

    property alias name: pageHeader.title
    property string host
    property int port
    property string selector
    property string query
    property string type
    property int encoding: Requester.EncAuto
    property bool showRawBuf
    property bool portraitReflow: Model.getConfig(Model.cfgPortraitReflow) === "true";
    property int historyIndex: 0
    property bool unloaded: false

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
                height: searchFieldInfo.implicitHeight + searchField.implicitHeight + Theme.paddingLarge
                visible: false

                Text {
                    id: searchFieldInfo
                    anchors.top: parent.top
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeMedium
                    wrapMode: Text.Wrap
                }

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
                    anchors.top: searchFieldInfo.bottom
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
                property int sidePadding: Theme.horizontalPageMargin
                x: sidePadding * 0.75
                width: parent.width - sidePadding
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
                    case 'gemini':
                        var wentBack = false;
                        if (Model.getConfig(Model.cfgHistoryGoBackIfSelectorExists) === "true") {
                            for (var i = Model.history.count - 1 - historyIndex; i < Model.history.count; ++i) {
                                var entry = Model.history.get(i);
                                if (entry.host === dlink.host && entry.port === dlink.port
                                        && Utils.removeTrailingSlash(entry.selector) === Utils.removeTrailingSlash(dlink.selector)
                                        && entry.query === entry.query)
                                {
                                    pageStack.pop(Model.historyPages[Model.history.count - 1 - i]);
                                    wentBack = true;
                                    break;
                                }
                            }
                        }
                        if (!wentBack) {
                            dlink.encoding = requester.responseEncoding();
                            pageStack.push("Browser.qml", dlink);
                        }
                        break;
                    default:
                        pageStack.push("Details.qml", dlink);
                        break;
                    }
                }
            }

            Item {
                width: 1;
                height: Theme.paddingLarge
                visible: !contentImage.loaded
            }

            ImageDisplay {
                id: contentImage
                visible: false
            }

            BusyIndicator {
                id: busyIndicator
                anchors.horizontalCenter: parent.horizontalCenter
                size: BusyIndicatorSize.Medium;
                running: !requestEnded;
                visible: running
            }
        }
    }

    property var links: []
    property bool requestEnded: true;
    property string cutebuf: ""
    property string rawbuf: ""

    Requester {
        id: requester

        onR_gemini_header: {
            searchFieldItem.visible = (status == Requester.GeminiInput || status == Requester.GeminiInputSensitive);
            searchField.echoMode = (status == Requester.GeminiInputSensitive ? TextInput.Password : TextInput.Normal);
            searchField.placeholderText = "";
            searchFieldInfo.visible = true;
            searchFieldInfo.text = meta;
        }

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
                query: query,
                name: name,
                historyIndex: historyIndex + 1,
            };

            if (type == '9' && Model.getConfig(Model.cfgOpenBinaryAsText) === "true") link.type = "0";

            if (type == '7' && host == page.host) link.encoding = requester.responseEncoding();

            var ilink = links.length;
            links[ilink] = link;

            parserWorker.sendMessage({ action: "link", type: type, name: name, ilink: ilink, selector: selector });
        }

        onR_gemini_section: {
            parserWorker.sendMessage({ action: "gemini_section", level: level, text: text });
        }

        onR_gemini_list: {
            parserWorker.sendMessage({ action: "gemini_list", text: text });
        }

        onR_gemini_pre_start: {
            parserWorker.sendMessage({ action: "gemini_pre_toggle", value: true, alt_text: alt_text });
        }

        onR_gemini_pre_stop: {
            parserWorker.sendMessage({ action: "gemini_pre_toggle", value: false });
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

        onR_gemini_data_link: {
            if (content_type.substring(0, 6) == "image/") {
                content.visible = false;
                busyIndicator.visible = false;
                contentImage.visible = true;
                contentImage.load(url);
            }
        }
    }

    Component.onCompleted: {
        updateContentAspect();
        var entry = { title: name, type: type, host: host, port: port, selector: selector, query: query };

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

        load();
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
            if (!pageStack.busy) {
                if (pageStack.currentPage === page) {
                    if (unloaded) {
                        load();
                    } else {
                        bufUpdateTimer.start();
                    }
                }
            } else {
                console.log("I’m page", historyIndex, ", unloaded(", unloaded, "), I see depth ", pageStack.depth)
                if (unloaded && historyIndex == pageStack.depth - 3) {
                    load();
                } else if (!unloaded && historyIndex === pageStack.depth - 12) {
                    // TODO using pageStack.depth isn’t optimal
                    unloaded = true;
                    content.text = "";
                    cutebuf = "";
                    rawbuf = "";
                    contentImage.unload();
                    console.log("Unloading", historyIndex)
                }
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
        query = searchField.text.trim();
        requester.open(host, port, selector, query, type, encoding);
        requestEnded = false;
        bufUpdateTimer.start();
    }

    function updateContentAspect() {
        var portrait = orientation == Orientation.Portrait || orientation == Orientation.PortraitInverted;
        showRawBuf = type != "gemini" && (!portrait || !portraitReflow)

        if (portrait || type === "gemini") {
            if (portraitReflow || type === "gemini") {
                content.font.pixelSize = parseInt(Model.getConfig(Model.cfgReflowFontSize)) || Model.preferredReflowedFontSize;
                content.lineHeight = 1.0;
            } else {
                content.font.pixelSize = parseInt(Model.getConfig(Model.cfgPortraitRawFontSize)) || Model.preferredPortraitFontSize;
                content.lineHeight = parseFloat(Model.getConfig(Model.cfgRawLineHeight));
            }
        } else {
            content.font.pixelSize = parseInt(Model.getConfig(Model.cfgLandscapeRawFontSize)) || Model.preferredLandscapeFontSize;
            content.lineHeight = parseFloat(Model.getConfig(Model.cfgRawLineHeight));
        }
        content.text = showRawBuf ? rawbuf : cutebuf;
    }

    function load() {
        unloaded = false;
        if (type != '7') {
            requestEnded = false;
            requester.open(host, port, selector, query, type, encoding);
        } else {
            searchFieldItem.visible = true;
            searchField.focus = true;
        }
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
