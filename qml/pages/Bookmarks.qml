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
import "."
import ".."

Page {
    id: page

    allowedOrientations: Model.allowedOrientations

    SilicaListView {
        id: listView
        anchors.fill: parent
        VerticalScrollDecorator { flickable: listView }

        PullDownMenu {
            MenuItem {
                text: "About"
                onClicked: {
                    pageStack.push("About.qml");
                }
            }
            MenuItem {
                text: "Settings"
                onClicked: {
                    pageStack.push("Settings.qml", { acceptDestination: page });
                }
            }
            MenuItem {
                text: "New Bookmark"
                onClicked: {
                    pageStack.push("Bookmark.qml", { acceptDestination: page });
                }
            }
        }

        header: PageHeader {
            width: parent.width
            title: "Gopherette"
        }

        model: Model.bookmarks

        delegate: ListItem {
            id: listItem
            width: parent.width
            contentHeight: content.implicitHeight + Theme.paddingSmall * 2

            onClicked: {
                pageStack.push("Browser.qml", {
                                   name: model.name,
                                   host: model.host,
                                   port: model.port,
                                   encoding: GopherRequest.EncAuto,
                                   type: model.type,
                                   selector: model.selector,
                                   historyIndex: 0,
                               });
            }

            function remove() {
                remorseAction("Remove " + name, function() { Model.delBookmark(id) });
            }

            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: "Edit"
                        onClicked: {
                            pageStack.push("Bookmark.qml", {
                                               idx: model.index,
                                               acceptDestination: page
                                           });
                        }
                    }
                    MenuItem {
                        text: "Remove"
                        onClicked: remove();
                    }
                }
            }

            Column {
                id: content
                width: parent.width - Theme.horizontalPageMargin * 2
                x: Theme.horizontalPageMargin
                y: Theme.paddingSmall

                Label {
                    width: parent.width
                    color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                    text: model.name
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                Label {
                    width: parent.width
                    color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    text: {
                        var r = model.host;
                        if (model.type === "gemini") {
                            if (model.port !== 1965) r += ":" + model.port;
                            if (model.selector !== "" && model.selector[0] !== "/") r += "/";
                        } else {
                            if (model.port !== 70) r += ":" + model.port;
                            r += "/" + model.type;
                        }
                        return r + model.selector;
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    truncationMode: TruncationMode.Fade
                    maximumLineCount: 1
                }
            }
        }
    }

    Component.onCompleted: {
        Model.bookmarksPage = this;
    }
}
