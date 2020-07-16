import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Dialog {

    acceptDestinationAction: PageStackAction.Pop
    allowedOrientations: Model.allowedOrientations

    property string server;
    property int port;
    property string fp;
    property bool first;
    property bool cn_ok;
    property string cns;
    property var requester;

    onAccepted: {
        requester.acceptCertificate();
    }

    onRejected: {
        requester.abort();
    }

    DialogHeader { }

    Column {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - Theme.horizontalPageMargin * 2
        x: Theme.horizontalPageMargin
        spacing: Theme.paddingLarge

        Label {
            text: first ? "This server has never been visited before." : "The certificate of this server has changed."
            width: parent.width
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.highlightColor
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
        }

        Grid {
            id: grid
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 2
            columnSpacing: Theme.paddingMedium

            Label {
                text: "Server"
                color: Theme.secondaryHighlightColor
            }

            Label {
                text: server
                color: Theme.highlightColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width: 2 * content.width / 3
            }

            Label {
                text: "Port"
                color: Theme.secondaryHighlightColor
            }


            Label {
                text: port
                color: Theme.highlightColor
            }
/*
            Label {
                text: "CN"
                color: Theme.secondaryHighlightColor
            }

            Label {
                text: cn_ok ? "Present" : "Absent"
                color: cn_ok ? Theme.highlightColor : "red"
            }

            Label {
                text: "CN List"
                color: Theme.secondaryHighlightColor
            }

            Label {
                text: cns
                color: Theme.highlightColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width: 2 * content.width / 3
            }
*/
            Label {
                text: "Hash"
                color: Theme.secondaryHighlightColor
            }

            Label {
                text: fp.replace(/..(?=.)/g, function (m) { return m + ":"; })
                color: Theme.highlightColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width: 2 * content.width / 3
            }
        }
    }
}
