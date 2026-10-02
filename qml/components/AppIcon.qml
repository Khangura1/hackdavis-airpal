import QtQuick 6.2

Item {
    id: icon
    property string name: "activity"
    property color lineColor: "#272635"
    property real lineWidth: Math.max(2, width * 0.08)

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        function rr(ctx, x, y, w, h, r) {
            ctx.beginPath()
            ctx.moveTo(x + r, y)
            ctx.lineTo(x + w - r, y)
            ctx.quadraticCurveTo(x + w, y, x + w, y + r)
            ctx.lineTo(x + w, y + h - r)
            ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
            ctx.lineTo(x + r, y + h)
            ctx.quadraticCurveTo(x, y + h, x, y + h - r)
            ctx.lineTo(x, y + r)
            ctx.quadraticCurveTo(x, y, x + r, y)
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = icon.lineColor
            ctx.fillStyle = icon.lineColor
            ctx.lineWidth = icon.lineWidth
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            var w = width
            var h = height
            var n = icon.name

            if (n === "activity") {
                ctx.beginPath()
                ctx.moveTo(w * 0.10, h * 0.55)
                ctx.lineTo(w * 0.28, h * 0.55)
                ctx.lineTo(w * 0.39, h * 0.28)
                ctx.lineTo(w * 0.54, h * 0.80)
                ctx.lineTo(w * 0.66, h * 0.43)
                ctx.lineTo(w * 0.76, h * 0.55)
                ctx.lineTo(w * 0.90, h * 0.55)
                ctx.stroke()
            } else if (n === "map") {
                ctx.beginPath()
                ctx.moveTo(w * 0.15, h * 0.28)
                ctx.lineTo(w * 0.38, h * 0.18)
                ctx.lineTo(w * 0.38, h * 0.76)
                ctx.lineTo(w * 0.15, h * 0.86)
                ctx.closePath()
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(w * 0.38, h * 0.18)
                ctx.lineTo(w * 0.62, h * 0.28)
                ctx.lineTo(w * 0.62, h * 0.86)
                ctx.lineTo(w * 0.38, h * 0.76)
                ctx.closePath()
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(w * 0.62, h * 0.28)
                ctx.lineTo(w * 0.85, h * 0.18)
                ctx.lineTo(w * 0.85, h * 0.76)
                ctx.lineTo(w * 0.62, h * 0.86)
                ctx.closePath()
                ctx.stroke()
            } else if (n === "factory") {
                ctx.beginPath()
                ctx.moveTo(w * 0.18, h * 0.84)
                ctx.lineTo(w * 0.18, h * 0.26)
                ctx.lineTo(w * 0.30, h * 0.26)
                ctx.lineTo(w * 0.30, h * 0.56)
                ctx.lineTo(w * 0.46, h * 0.42)
                ctx.lineTo(w * 0.46, h * 0.56)
                ctx.lineTo(w * 0.64, h * 0.42)
                ctx.lineTo(w * 0.64, h * 0.84)
                ctx.lineTo(w * 0.18, h * 0.84)
                ctx.closePath()
                ctx.stroke()
                for (var i = 0; i < 3; i++) {
                    ctx.beginPath()
                    ctx.rect(w * (0.30 + i * 0.14), h * 0.68, w * 0.055, h * 0.055)
                    ctx.stroke()
                }
            } else if (n === "wind") {
                ctx.beginPath()
                ctx.moveTo(w * 0.16, h * 0.34)
                ctx.lineTo(w * 0.62, h * 0.34)
                ctx.quadraticCurveTo(w * 0.85, h * 0.34, w * 0.78, h * 0.18)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(w * 0.12, h * 0.54)
                ctx.lineTo(w * 0.72, h * 0.54)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(w * 0.22, h * 0.74)
                ctx.lineTo(w * 0.58, h * 0.74)
                ctx.quadraticCurveTo(w * 0.80, h * 0.74, w * 0.76, h * 0.88)
                ctx.stroke()
            } else if (n === "droplet") {
                ctx.beginPath()
                ctx.moveTo(w * 0.38, h * 0.18)
                ctx.quadraticCurveTo(w * 0.18, h * 0.45, w * 0.22, h * 0.60)
                ctx.quadraticCurveTo(w * 0.28, h * 0.82, w * 0.48, h * 0.76)
                ctx.quadraticCurveTo(w * 0.64, h * 0.70, w * 0.60, h * 0.52)
                ctx.quadraticCurveTo(w * 0.56, h * 0.38, w * 0.38, h * 0.18)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(w * 0.66, h * 0.20)
                ctx.quadraticCurveTo(w * 0.50, h * 0.48, w * 0.56, h * 0.64)
                ctx.quadraticCurveTo(w * 0.66, h * 0.86, w * 0.82, h * 0.68)
                ctx.quadraticCurveTo(w * 0.90, h * 0.52, w * 0.66, h * 0.20)
                ctx.stroke()
            } else if (n === "warning") {
                ctx.beginPath()
                ctx.moveTo(w * 0.50, h * 0.12)
                ctx.lineTo(w * 0.90, h * 0.84)
                ctx.lineTo(w * 0.10, h * 0.84)
                ctx.closePath()
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(w * 0.50, h * 0.38)
                ctx.lineTo(w * 0.50, h * 0.60)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(w * 0.50, h * 0.72, Math.max(2, w * 0.035), 0, 2 * Math.PI)
                ctx.fill()
            }
        }
    }

    onNameChanged: canvas.requestPaint()
    onLineColorChanged: canvas.requestPaint()
    onLineWidthChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
}
