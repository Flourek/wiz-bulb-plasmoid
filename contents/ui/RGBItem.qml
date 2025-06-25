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

    property alias redSlider: redControl
    property alias greenSlider: greenControl
    property alias blueSlider: blueControl
    
    property int redValue: 255
    property int greenValue: 255
    property int blueValue: 255

    signal colorChanged(string channel, int value)

    background.visible: highlighted
    highlighted: activeFocus
    hoverEnabled: false

    Accessible.ignored: true
    Keys.forwardTo: [redControl, greenControl, blueControl]

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: i18n("RGB Color Control")
            textFormat: Text.PlainText
            font.bold: true
            font.family: "monospace"
            Accessible.ignored: true
        }

        // Red slider
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.gridUnit

            PlasmaComponents3.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                text: "R:"
                textFormat: Text.PlainText
                color: "#FF4444"
                font.family: "monospace"
                font.bold: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: i18n("Red Channel")
                        textFormat: Text.PlainText
                        color: "#FF4444"
                        font.family: "monospace"
                    }

                    PlasmaComponents3.Label {
                        text: "0x" + redValue.toString(16).padStart(2, '0').toUpperCase()
                        textFormat: Text.PlainText
                        font.family: "monospace"
                        color: "#FF4444"
                    }
                }

                PlasmaComponents3.Slider {
                    id: redControl
                    Layout.fillWidth: true
                    from: 0
                    to: 255
                    stepSize: 1
                    value: root.redValue

                    handle: Rectangle {
                        x: redControl.leftPadding + redControl.visualPosition * (redControl.availableWidth - width)
                        y: redControl.topPadding + redControl.availableHeight / 2 - height / 2
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 10
                        color: "#FF4444"
                        border.color: "#FFFFFF"
                        border.width: 2
                    }

                    background: Rectangle {
                        x: redControl.leftPadding
                        y: redControl.topPadding + redControl.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 6
                        width: redControl.availableWidth
                        height: implicitHeight
                        radius: 3
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#000000" }
                            GradientStop { position: 1.0; color: "#FF0000" }
                        }
                        border.color: "#444444"
                        border.width: 1
                    }

                    onMoved: {
                        root.redValue = value;
                        root.colorChanged("red", value);
                    }
                }
            }
        }

        // Green slider
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.gridUnit

            PlasmaComponents3.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                text: "G:"
                textFormat: Text.PlainText
                color: "#44FF44"
                font.family: "monospace"
                font.bold: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: i18n("Green Channel")
                        textFormat: Text.PlainText
                        color: "#44FF44"
                        font.family: "monospace"
                    }

                    PlasmaComponents3.Label {
                        text: "0x" + greenValue.toString(16).padStart(2, '0').toUpperCase()
                        textFormat: Text.PlainText
                        font.family: "monospace"
                        color: "#44FF44"
                    }
                }

                PlasmaComponents3.Slider {
                    id: greenControl
                    Layout.fillWidth: true
                    from: 0
                    to: 255
                    stepSize: 1
                    value: root.greenValue

                    handle: Rectangle {
                        x: greenControl.leftPadding + greenControl.visualPosition * (greenControl.availableWidth - width)
                        y: greenControl.topPadding + greenControl.availableHeight / 2 - height / 2
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 10
                        color: "#44FF44"
                        border.color: "#FFFFFF"
                        border.width: 2
                    }

                    background: Rectangle {
                        x: greenControl.leftPadding
                        y: greenControl.topPadding + greenControl.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 6
                        width: greenControl.availableWidth
                        height: implicitHeight
                        radius: 3
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#000000" }
                            GradientStop { position: 1.0; color: "#00FF00" }
                        }
                        border.color: "#444444"
                        border.width: 1
                    }

                    onMoved: {
                        root.greenValue = value;
                        root.colorChanged("green", value);
                    }
                }
            }
        }

        // Blue slider
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.gridUnit

            PlasmaComponents3.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                text: "B:"
                textFormat: Text.PlainText
                color: "#4444FF"
                font.family: "monospace"
                font.bold: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: i18n("Blue Channel")
                        textFormat: Text.PlainText
                        color: "#4444FF"
                        font.family: "monospace"
                    }

                    PlasmaComponents3.Label {
                        text: "0x" + blueValue.toString(16).padStart(2, '0').toUpperCase()
                        textFormat: Text.PlainText
                        font.family: "monospace"
                        color: "#4444FF"
                    }
                }

                PlasmaComponents3.Slider {
                    id: blueControl
                    Layout.fillWidth: true
                    from: 0
                    to: 255
                    stepSize: 1
                    value: root.blueValue

                    handle: Rectangle {
                        x: blueControl.leftPadding + blueControl.visualPosition * (blueControl.availableWidth - width)
                        y: blueControl.topPadding + blueControl.availableHeight / 2 - height / 2
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 10
                        color: "#4444FF"
                        border.color: "#FFFFFF"
                        border.width: 2
                    }

                    background: Rectangle {
                        x: blueControl.leftPadding
                        y: blueControl.topPadding + blueControl.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 6
                        width: blueControl.availableWidth
                        height: implicitHeight
                        radius: 3
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#000000" }
                            GradientStop { position: 1.0; color: "#0000FF" }
                        }
                        border.color: "#444444"
                        border.width: 1
                    }

                    onMoved: {
                        root.blueValue = value;
                        root.colorChanged("blue", value);
                    }
                }
            }
        }

        // Color preview
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            color: Qt.rgba(redValue/255, greenValue/255, blueValue/255, 1.0)
            border.width: 2
            border.color: "#444444"
            radius: 2

            PlasmaComponents3.Label {
                anchors.centerIn: parent
                text: "RGB(" + redValue + "," + greenValue + "," + blueValue + ")"
                color: (redValue + greenValue + blueValue > 384) ? "#000000" : "#FFFFFF"
                font.family: "monospace"
                font.bold: true
            }
        }
    }
}
