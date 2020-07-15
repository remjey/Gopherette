import QtQuick 2.0
import Sailfish.Silica 1.0

MouseArea {
    width: parent.width
    height: Math.max(imageBusy.height, pic.height)

    function load(url) {
        imageBusy.running = true;
        pic.source = url;
        loaded = false;
    }

    function unload() {
        imageBusy.running = false;
        pic.source = "";
        loaded = false;
    }

    property bool loaded: loaded;

    BusyIndicator {
        id: imageBusy
        size: BusyIndicatorSize.Medium
        anchors.horizontalCenter: parent.horizontalCenter
    }

    onWidthChanged: pic.updateSize()

    Image {
        id: pic
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
                loaded = true;
            } else if (status == Image.Error) {
                imageBusy.running = false;
            }
        }
    }
}
