
import QtQuick 2.0
import QtMultimedia 5.0

import Sailfish.Silica 1.0

MouseArea {

    width: parent.width
    height: Theme.paddingLarge

    IconButton {
        icon.source: "image://theme/icon-l-play"
    }

    Audio {
        id: audio
        onStatusChanged: {
            console.log("Audio player status: " + status)
        }
        onError: {
            console.log("Audio player error: " + error + ": " + errorString)
        }
    }

}
