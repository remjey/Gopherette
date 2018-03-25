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

Page {
    id: page

    property int historyIndex

    allowedOrientations: Model.allowedOrientations

    SilicaListView {
        id: listView
        anchors.fill: parent
        VerticalScrollDecorator { flickable: listView }

        header: PageHeader {
            width: parent.width
            title: "History"
        }

        model: Model.history

        delegate: ListItem {
            id: listItem
            width: parent.width
            contentHeight: content.implicitHeight + Theme.paddingSmall * 2

            onClicked: {
                pageStack.pop(Model.historyPages[Model.history.count - 1 - model.index]);
            }

            Column {
                id: content
                width: parent.width - Theme.horizontalPageMargin * 2
                x: Theme.horizontalPageMargin
                y: Theme.paddingSmall

                Label {
                    width: parent.width
                    color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                    text: model.title
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                Label {
                    width: parent.width
                    color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    text: model.host + ":" + model.port + "/" + model.type + model.selector
                    font.pixelSize: Theme.fontSizeSmall
                    truncationMode: TruncationMode.Fade
                    maximumLineCount: 1
                }
            }
        }

        footer: Item {
            width: parent.width
            height: bookmarksButton.height + Theme.paddingLarge * 2
            Button {
                id: bookmarksButton
                anchors.centerIn: parent
                text: "Back to bookmarks"
                onClicked: pageStack.pop(Model.bookmarksPage)
            }
        }
    }

    Component.onCompleted: {
        while (Model.history.count - 1 - historyIndex > 0) {
            Model.historyPages[Model.history.count - 1] = false;
            Model.history.remove(0);
        }
    }
}
