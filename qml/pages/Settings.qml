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

    acceptDestinationAction: PageStackAction.Pop
    allowedOrientations: Model.allowedOrientations

    property var cfm: ({
                           "portrait.reflow": {
                               label: "Reflow documents when in portrait mode",
                               type: "bool",
                           },
                           "reflow.font.smaller": {
                               label: "Use a smaller font for reflowed documents",
                               type: "bool",
                           },
                           "portrait.raw.font.size": {
                               label: "Non-reflowed portrait mode font size",
                               type: "text",
                               hints: Qt.ImhDigitsOnly,
                           },
                           "landscape.raw.font.size": {
                               label: "Landscape mode font size",
                               type: "text",
                               hints: Qt.ImhDigitsOnly,
                           },
                           "open.binary.as.text": {
                               label: "Open binary files as text",
                               desc: "This is a dangerous option, Gopherette may misbehave if the content being displayed isn’t text.",
                               type: "bool",
                           },
                           "history.go.back.if.selector.exists": {
                               label: "If clicked selector exists in history, act as if it was clicked in the history.",
                               type: "bool",
                           },
                           "raw.line.height": {
                               label: "Line height in raw text mode",
                               type: "slider",
                               min: 1.0,
                               max: 2.0,
                               step: 0.01,
                           }
                       })

    property var modified: ({})

    onAccepted: {
        for (var k in modified) {
            Model.setConfig(k, modified[k]);
        }
    }

    SilicaFlickable {        
        anchors.fill: parent
        contentHeight: content.height

        VerticalScrollDecorator {}

        Column {
            id: content
            width: parent.width

            DialogHeader { title: "Settings" }

            Repeater {
                model: Model.config

                delegate: Loader {
                    width: parent.width
                    height: implicitHeight
                    property string k: model.k
                    property string v: model.v
                    Component.onCompleted: {
                        switch (cfm[model.k].type) {
                        case "text": sourceComponent = configTextField; break;
                        case "bool": sourceComponent = configTextSwitch; break;
                        case "slider": sourceComponent = configSlider; break;
                        }
                    }
                }
            }
        }
    }

    Component {
        id: configTextField
        TextField {
            width: parent.width
            placeholderText: label
            label: cfm[parent.k].label || parent.k
            text: parent.v || ""
            inputMethodHints: cfm[parent.k].hints || (Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase)
            onTextChanged: modified[parent.k] = text;
        }
    }

    Component {
        id: configTextSwitch
        TextSwitch {
            width: parent.width
            text: cfm[parent.k].label || parent.k
            description: cfm[parent.k].desc || ""
            checked: parent.v === "true"
            onCheckedChanged: modified[parent.k] = checked ? "true" : "false";
        }
    }

    Component {
        id: configSlider
        Slider {
            value: Math.round(parseFloat(parent.v) / cfm[parent.k].step) * cfm[parent.k].step
            minimumValue: cfm[parent.k].min || 0.0
            maximumValue: cfm[parent.k].max || 100.0
            stepSize: cfm[parent.k].step || 1.0
            width: parent.width
            valueText: value.toFixed(2)
            label: cfm[parent.k].label
            onValueChanged: modified[parent.k] = value.toString();
        }
    }
}

