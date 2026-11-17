// Sunshine OS welcome animation: the pixel-art Sunshine logo builds up, then rests while the session loads.
import QtQuick 2.15

Rectangle {
    id: root
    color: "#0b1020"
    property int stage
    readonly property int frames: 180
    readonly property int cols: 12
    readonly property int cell: 80
    property int frame: 0

    Image {
        id: logo
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -parent.height * 0.04
        width: root.cell * 4; height: width
        source: "images/logo-sprite.png"
        smooth: false; mipmap: false
        sourceClipRect: Qt.rect((root.frame % root.cols) * root.cell, Math.floor(root.frame / root.cols) * root.cell, root.cell, root.cell)
    }
    Timer {
        interval: 28; running: true; repeat: true
        onTriggered: if (root.frame < root.frames - 1) root.frame++
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: logo.bottom; anchors.topMargin: 24
        text: "Sunshine OS"; color: "#ffd27a"; font.pixelSize: 26; font.letterSpacing: 4; font.bold: true
        opacity: Math.min(1, root.frame / 90)
    }
    Rectangle {      // progress: orange to gold
        id: track
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: parent.height * 0.12
        width: Math.min(parent.width * 0.3, 420); height: 4; radius: 2; color: "#24202a"
        Rectangle {
            height: parent.height; radius: 2
            width: parent.width * Math.min(1, root.stage / 6)
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#e87932" } GradientStop { position: 0.6; color: "#f5a442" } GradientStop { position: 1.0; color: "#ffd27a" } }
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
        }
    }
}
