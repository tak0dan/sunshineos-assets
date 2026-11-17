// Sunshine graphs: four small live line graphs (network, disk space, CPU, GPU) in orange / amber / gold, for the top bar.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root
    preferredRepresentation: compactRepresentation
    compactRepresentation: Graphs {}
    fullRepresentation: Graphs {}
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    readonly property var graphs: [
        { label: "NET", ids: ["network/all/download", "network/all/upload"], color: "#6fd3c0", color2: "#5aa9f0", max: 0 },
        { label: "DISK", ids: ["disk/all/usedPercent"], color: "#c4a0ff", max: 100 },
        { label: "CPU", ids: ["cpu/all/usage"], color: "#ff8f6b", max: 100 },
        { label: "GPU", ids: ["gpu/gpu1/usage", "gpu/gpu0/usage"], color: "#9be37a", max: 100 }
    ]

    component Graphs: RowLayout {
        spacing: Kirigami.Units.largeSpacing
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        Repeater {
            model: root.graphs
            delegate: Item {
                id: cell
                required property var modelData
                implicitWidth: Kirigami.Units.gridUnit * 6.5
                implicitHeight: Kirigami.Units.gridUnit * 1.6
                Layout.fillHeight: true
                property var hist: []
                property var hist2: []
                property real value: 0
                property real value2: 0
                property real maxv: modelData.max > 0 ? modelData.max : 1

                // the GPU sensor id differs between drivers: the first id that reports a value wins
                Sensors.Sensor { id: s1; sensorId: modelData.ids[0]; enabled: true }
                Sensors.Sensor { id: s1b; sensorId: modelData.ids.length > 1 && modelData.label === "GPU" ? modelData.ids[1] : ""; enabled: modelData.label === "GPU" }
                Sensors.Sensor { id: s2; sensorId: modelData.label === "NET" ? modelData.ids[1] : ""; enabled: modelData.label === "NET" }

                function num(x) { var v = Number(x); return isNaN(v) ? 0 : v }
                Timer {
                    interval: 1000; running: true; repeat: true; triggeredOnStart: true
                    onTriggered: {
                        var v = cell.num(s1.value); if (v === 0 && modelData.label === "GPU") v = cell.num(s1b.value)
                        cell.value = v
                        var h = cell.hist.slice(-39); h.push(v); cell.hist = h
                        if (modelData.label === "NET") {
                            cell.value2 = cell.num(s2.value)
                            var h2 = cell.hist2.slice(-39); h2.push(cell.value2); cell.hist2 = h2
                            var m = 1024 * 10; for (var i = 0; i < h.length; i++) m = Math.max(m, h[i], h2[i] || 0)
                            cell.maxv = m
                        }
                        canvas.requestPaint()
                    }
                }
                Canvas {
                    id: canvas
                    anchors.fill: parent
                    anchors.topMargin: 3; anchors.bottomMargin: 3
                    onPaint: {
                        var c = getContext("2d"); c.reset()
                        var w = width, h = height, n = 40
                        function line(data, col, alpha) {
                            if (data.length < 2) return
                            c.beginPath()
                            for (var i = 0; i < data.length; i++) {
                                var x = w - (data.length - 1 - i) * (w / (n - 1))
                                var y = h - Math.min(1, data[i] / cell.maxv) * (h - 2) - 1
                                if (i === 0) c.moveTo(x, y); else c.lineTo(x, y)
                            }
                            c.strokeStyle = col; c.lineWidth = 1.5; c.stroke()
                            c.lineTo(w, h); c.lineTo(w - (data.length - 1) * (w / (n - 1)), h); c.closePath()
                            var gr = c.createLinearGradient(0, 0, 0, h); gr.addColorStop(0, col); gr.addColorStop(1, "rgba(0,0,0,0)"); c.globalAlpha = Math.min(1, alpha * 2.4); c.fillStyle = gr; c.fill(); c.globalAlpha = 1
                        }
                        line(cell.hist, modelData.color, 0.18)
                        if (modelData.label === "NET") line(cell.hist2, modelData.color2, 0.12)
                    }
                }
                Text {
                    anchors.left: parent.left; anchors.top: parent.top
                    text: modelData.label + (modelData.label === "NET" ? "" : " " + Math.round(cell.value) + "%")
                    color: "#f4f0eb"; opacity: 0.85
                    font.pixelSize: Kirigami.Units.gridUnit * 0.6; font.bold: true
                }
            }
        }
    }
}
