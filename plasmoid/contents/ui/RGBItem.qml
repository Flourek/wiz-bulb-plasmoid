/*
    SPDX-FileCopyrightText: 2024 Wiz Control Developer

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmaComponents3.ItemDelegate {
    id: root

    property int redValue: 255
    property int greenValue: 255
    property int blueValue: 255

    signal colorChanged(string channel, int value)

    background.visible: highlighted
    highlighted: activeFocus
    hoverEnabled: true

    Accessible.ignored: true

    // Custom Color Picker Dialog
    PlasmaComponents3.Dialog {
        id: colorDialog
        title: i18n("Select RGB Color")
        modal: true
        
        // Fix positioning - center horizontally, move up by dialog height
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2) - height
        
        property real currentHue: 0.0
        property real currentSaturation: 1.0
        property real currentValue: 1.0
        
        // Convert current RGB to HSV on open
        function updateFromRGB() {
            var hsv = rgbToHsv(root.redValue, root.greenValue, root.blueValue)
            currentHue = hsv.h
            currentSaturation = hsv.s
            currentValue = hsv.v
        }
        
        function rgbToHsv(r, g, b) {
            r /= 255; g /= 255; b /= 255
            var max = Math.max(r, g, b), min = Math.min(r, g, b)
            var h, s, v = max
            var d = max - min
            s = max == 0 ? 0 : d / max
            if (max == min) {
                h = 0
            } else {
                switch (max) {
                    case r: h = (g - b) / d + (g < b ? 6 : 0); break
                    case g: h = (b - r) / d + 2; break
                    case b: h = (r - g) / d + 4; break
                }
                h /= 6
            }
            return {h: h, s: s, v: v}
        }
        
        function hsvToRgb(h, s, v) {
            var r, g, b
            var i = Math.floor(h * 6)
            var f = h * 6 - i
            var p = v * (1 - s)
            var q = v * (1 - f * s)
            var t = v * (1 - (1 - f) * s)
            switch (i % 6) {
                case 0: r = v, g = t, b = p; break
                case 1: r = q, g = v, b = p; break
                case 2: r = p, g = v, b = t; break
                case 3: r = p, g = q, b = v; break
                case 4: r = t, g = p, b = v; break
                case 5: r = v, g = p, b = q; break
            }
            return {
                r: Math.round(r * 255),
                g: Math.round(g * 255),
                b: Math.round(b * 255)
            }
        }
        
        function updateColor() {
            var rgb = hsvToRgb(currentHue, currentSaturation, currentValue)
            root.redValue = rgb.r
            root.greenValue = rgb.g
            root.blueValue = rgb.b
            
            // Emit individual color changes to maintain compatibility
            root.colorChanged("red", root.redValue)
            root.colorChanged("green", root.greenValue)
            root.colorChanged("blue", root.blueValue)
        }
        
        onOpened: updateFromRGB()
        
        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing
            
            // Color Space (HSV Square) - Use Rectangle with gradient instead of Canvas
            Rectangle {
                Layout.preferredWidth: 200
                Layout.preferredHeight: 200
                border.color: "#444444"
                border.width: 1
                clip: true
                
                // Base hue color rectangle
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    color: {
                        var rgb = colorDialog.hsvToRgb(colorDialog.currentHue, 1.0, 1.0)
                        return Qt.rgba(rgb.r/255, rgb.g/255, rgb.b/255, 1.0)
                    }
                }
                
                // Saturation gradient (left to right: white to transparent)
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#FFFFFF" }
                        GradientStop { position: 1.0; color: "#00FFFFFF" } // Transparent white
                    }
                }
                
                // Value gradient (top to bottom: transparent to black)
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#00000000" } // Transparent black
                        GradientStop { position: 1.0; color: "#000000" }
                    }
                }
                
                // Color selection mouse area
                MouseArea {
                    anchors.fill: parent
                    
                    onClicked: (mouse) => {
                        colorDialog.currentSaturation = mouse.x / width
                        colorDialog.currentValue = (height - mouse.y) / height
                        colorDialog.updateColor()
                    }
                    
                    onPositionChanged: (mouse) => {
                        if (pressed) {
                            colorDialog.currentSaturation = Math.max(0, Math.min(1, mouse.x / width))
                            colorDialog.currentValue = Math.max(0, Math.min(1, (height - mouse.y) / height))
                            colorDialog.updateColor()
                        }
                    }
                }
                
                // Selection indicator
                Rectangle {
                    x: colorDialog.currentSaturation * (parent.width - width)
                    y: (1 - colorDialog.currentValue) * (parent.height - height)
                    width: 12
                    height: 12
                    radius: 6
                    border.color: "#FFFFFF"
                    border.width: 2
                    color: "transparent"
                    
                    Rectangle {
                        anchors.centerIn: parent
                        width: 8
                        height: 8
                        radius: 4
                        border.color: "#000000"
                        border.width: 1
                        color: "transparent"
                    }
                }
            }
            
            // Hue Slider
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                
                PlasmaComponents3.Label {
                    text: "Hue:"
                    font.family: "monospace"
                    font.bold: true
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    border.color: "#444444"
                    border.width: 1
                    
                    // Hue gradient background
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#FF0000" } // Red
                            GradientStop { position: 0.167; color: "#FFFF00" } // Yellow
                            GradientStop { position: 0.333; color: "#00FF00" } // Green
                            GradientStop { position: 0.5; color: "#00FFFF" } // Cyan
                            GradientStop { position: 0.667; color: "#0000FF" } // Blue
                            GradientStop { position: 0.833; color: "#FF00FF" } // Magenta
                            GradientStop { position: 1.0; color: "#FF0000" } // Red
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        
                        onClicked: (mouse) => {
                            colorDialog.currentHue = mouse.x / width
                            colorDialog.updateColor()
                        }
                        
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                colorDialog.currentHue = Math.max(0, Math.min(1, mouse.x / width))
                                colorDialog.updateColor()
                            }
                        }
                    }
                    
                    // Hue indicator
                    Rectangle {
                        x: colorDialog.currentHue * (parent.width - width)
                        y: -2
                        width: 4
                        height: parent.height + 4
                        color: "#FFFFFF"
                        border.color: "#000000"
                        border.width: 1
                    }
                }
            }
            
            // Action buttons
            RowLayout {
                Layout.fillWidth: true
                
                PlasmaComponents3.Button {
                    Layout.fillWidth: true
                    text: i18n("Cancel")
                    onClicked: colorDialog.close()
                }
                
                PlasmaComponents3.Button {
                    Layout.fillWidth: true
                    text: i18n("OK")
                    onClicked: {
                        colorDialog.updateColor()
                        colorDialog.close()
                    }
                }
            }
        }
    }

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: i18n("RGB Color Control")
            textFormat: Text.PlainText
            font.bold: true
            font.family: "monospace"
            Accessible.ignored: true
            horizontalAlignment: Text.AlignHCenter
        }

        // Color preview and picker button
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            // Color preview rectangle
            Rectangle {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                color: Qt.rgba(redValue/255, greenValue/255, blueValue/255, 1.0)
                border.width: 2
                border.color: "#444444"
                radius: 4

                PlasmaComponents3.Label {
                    anchors.centerIn: parent
                    text: "RGB"
                    color: (redValue + greenValue + blueValue > 384) ? "#000000" : "#FFFFFF"
                    font.family: "monospace"
                    font.bold: true
                }
            }

            // Color picker button
            PlasmaComponents3.Button {
                Layout.fillWidth: true
                text: i18n("Choose Color")
                icon.name: "color-picker"
                
                onClicked: {
                    colorDialog.open()
                }
            }
        }

        // Color information display
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            // RGB values display
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Label {
                    text: "RGB:"
                    font.family: "monospace"
                    font.bold: true
                }

                PlasmaComponents3.Label {
                    text: "(" + redValue + "," + greenValue + "," + blueValue + ")"
                    font.family: "monospace"
                }
            }

            // Hex values display
            GridLayout {
                Layout.fillWidth: true
                columns: 6
                columnSpacing: Kirigami.Units.smallSpacing
                rowSpacing: 2

                PlasmaComponents3.Label {
                    text: "R:"
                    color: "#FF4444"
                    font.family: "monospace"
                    font.bold: true
                }
                PlasmaComponents3.Label {
                    text: "0x" + redValue.toString(16).padStart(2, '0').toUpperCase()
                    color: "#FF4444"
                    font.family: "monospace"
                }

                PlasmaComponents3.Label {
                    text: "G:"
                    color: "#44FF44"
                    font.family: "monospace"
                    font.bold: true
                }
                PlasmaComponents3.Label {
                    text: "0x" + greenValue.toString(16).padStart(2, '0').toUpperCase()
                    color: "#44FF44"
                    font.family: "monospace"
                }

                PlasmaComponents3.Label {
                    text: "B:"
                    color: "#4444FF"
                    font.family: "monospace"
                    font.bold: true
                }
                PlasmaComponents3.Label {
                    text: "0x" + blueValue.toString(16).padStart(2, '0').toUpperCase()
                    color: "#4444FF"
                    font.family: "monospace"
                }
            }

            // Full hex color display
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Label {
                    text: "HEX:"
                    font.family: "monospace"
                    font.bold: true
                }

                PlasmaComponents3.Label {
                    text: "#" + redValue.toString(16).padStart(2, '0').toUpperCase() + 
                          greenValue.toString(16).padStart(2, '0').toUpperCase() + 
                          blueValue.toString(16).padStart(2, '0').toUpperCase()
                    font.family: "monospace"
                    font.bold: true
                }
            }
        }
    }
}
