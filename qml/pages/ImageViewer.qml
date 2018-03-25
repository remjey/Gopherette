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

Page {
    id: root

    property alias title: header.title
    property alias url: image.source

    allowedOrientations: Model.allowedOrientations
    property bool fullView: false
    property real imageMinScale: 1
    property real imagePreviewScale: 1
    property real imageScale: 1

    onImageScaleChanged: print("changed " + imageScale);

    backNavigation: !fullView

    states: [
        State {
            name: "pi"
            PropertyChanges {
                target: infoItem
                height: root.height / 2
                width: root.width
            }
            PropertyChanges {
                target: imageI
                x: 0
                y: root.height / 2
                height: root.height / 2
                width: root.width
            }
            PropertyChanges {
                target: root
                imageScale: imagePreviewScale
            }
        },
        State {
            name: "pfv"
            PropertyChanges {
                target: infoItem
                height: 0
                width: root.width
            }
            PropertyChanges {
                target: imageI
                x: 0
                y: 0
                height: root.height
                width: root.width
            }
            PropertyChanges {
                target: root
                imageScale: imageMinScale
            }
        },
        State {
            name: "li"
            PropertyChanges {
                target: infoItem
                height: root.height
                width: root.width / 2
            }
            PropertyChanges {
                target: imageI
                x: root.width / 2
                y: 0
                height: root.height
                width: root.width / 2
            }
            PropertyChanges {
                target: root
                imageScale: imagePreviewScale
            }
        },
        State {
            name: "lfv"
            PropertyChanges {
                target: infoItem
                height: root.height
                width: 0
            }
            PropertyChanges {
                target: imageI
                x: 0
                y: 0
                height: root.height
                width: root.width
            }
            PropertyChanges {
                target: root
                imageScale: imageMinScale
            }
        }
    ]

    transitions: [
        Transition {
            from: "pi"
            to: "pfv"
            NumberAnimation {
                target: infoItem
                property: "height"
                duration: 1000
            }
            NumberAnimation {
                target: imageI
                properties: "height,y"
                duration: 1000
            }
            NumberAnimation {
                target: root
                properties: "imageScale"
                duration: 1000
            }
        },
        Transition {
            from: "pfv"
            to: "pi"
            NumberAnimation {
                target: infoItem
                property: "height"
                duration: 1000
            }
            NumberAnimation {
                target: imageI
                properties: "height,y"
                duration: 1000
            }
            NumberAnimation {
                target: root
                properties: "imageScale"
                duration: 1000
            }
        },
        Transition {
            from: "li"
            to: "lfv"
            NumberAnimation {
                target: infoItem
                property: "width"
                duration: 1000
            }
            NumberAnimation {
                target: imageI
                properties: "width,x"
                duration: 1000
            }
            NumberAnimation {
                target: root
                properties: "imageScale"
                duration: 1000
            }
        },
        Transition {
            from: "lfv"
            to: "li"
            NumberAnimation {
                target: infoItem
                property: "width"
                duration: 1000
            }
            NumberAnimation {
                target: imageI
                properties: "width,x"
                duration: 1000
            }
            NumberAnimation {
                target: root
                properties: "imageScale"
                duration: 1000
            }
        }
    ]

    Item {
        id: infoItem
        clip: true

        Column {
            id: info
            width: workingIsPortrait() ? root.width : root.width / 2
            height: workingIsPortrait() ? root.height / 2: root.height

            PageHeader {
                id: header
            }

            Label {
                width: parent.width - Theme.horizontalPageMargin * 2
                x: Theme.horizontalPageMargin
                text: url
                wrapMode: Text.WrapAnywhere
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }


    Item {
        id: imageI
        clip: true

        Flickable {
            id: imageC
            anchors.centerIn: parent
            width: root.width
            height: root.height

            contentHeight: imagePA.height
            contentWidth: imagePA.width

            interactive: fullView
            flickableDirection: Flickable.HorizontalAndVerticalFlick

            PinchArea {
                id: imagePA
                width: Math.max(imageC.width, image.width);
                height: Math.max(imageC.height, image.height);

                enabled: fullView

                onPinchUpdated: {
                    var nsc = Math.max(imageMinScale, imageScale * pinch.scale / pinch.previousScale);
                    var opaw = imagePA.width;
                    var opah = imagePA.height;
                    print("pinch to " + nsc)
                    imageScale = nsc;
                    var rw = pinch.center.x / imagePA.width;
                    var rh = pinch.center.y / imagePA.height;
                    imageC.contentX -= (opaw - imagePA.width) * rw;
                    imageC.contentY -= (opah - imagePA.height) * rh;
                }

                Image {
                    id: image
                    anchors.centerIn: parent

                    width: imageScale * implicitWidth
                    height: imageScale * implicitHeight

                    onStatusChanged: {
                        placeImage();
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (image.status == Image.Ready) {
                            fullView = !fullView;
                            reorient();
                        }
                    }
                }
            }
        }
    }

    function compImageScale(fill, cw, ch) {
        var icr = cw / ch;
        var ir = image.implicitWidth / image.implicitHeight;

        if ((fill && ir < icr) || (!fill && ir > icr)) {
            return cw / image.implicitWidth;
        } else {
            return ch / image.implicitHeight;
        }
    }

    function placeImage() {
        if (image.status != Image.Ready) return;

        imageMinScale = compImageScale(false, root.width, root.height);

        if (workingIsPortrait()) {
            imagePreviewScale = compImageScale(true, root.width, root.height / 2);
        } else {
            imagePreviewScale = compImageScale(true, root.width / 2, root.height);
        }
    }

    function reorient() {
        if (workingIsPortrait()) {
            state = fullView ? "pfv" : "pi";
        } else {
            state = fullView ? "lfv" : "li";
        }
    }

    onOrientationTransitionRunningChanged: {
        if (!orientationTransitionRunning) {
            placeImage();
        }
    }

    onOrientationChanged: reorient();


    function workingIsPortrait() {
        return orientation == Orientation.Portrait || orientation == Orientation.PortraitInverted;
    }

    Component.onCompleted: reorient();
}
