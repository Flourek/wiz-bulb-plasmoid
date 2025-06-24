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
            Accessible.ignored: true
        }

        // Red slider
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.gridUnit

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                source: "color-picker-red"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: i18n("Red")
                        textFormat: Text.PlainText
                        color: "#FF0000"
                    }

                    PlasmaComponents3.Label {
                        text: redValue
                        textFormat: Text.PlainText
                    }
                }

                PlasmaComponents3.Slider {
                    id: redControl
                    Layout.fillWidth: true
                    from: 0
                    to: 255
                    stepSize: 1
                    value: root.redValue

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

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                source: "color-picker-green"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: i18n("Green")
                        textFormat: Text.PlainText
                        color: "#00FF00"
                    }

                    PlasmaComponents3.Label {
                        text: greenValue
                        textFormat: Text.PlainText
                    }
                }

                PlasmaComponents3.Slider {
                    id: greenControl
                    Layout.fillWidth: true
                    from: 0
                    to: 255
                    stepSize: 1
                    value: root.greenValue

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

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                source: "color-picker-blue"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: i18n("Blue")
                        textFormat: Text.PlainText
                        color: "#0000FF"
                    }

                    PlasmaComponents3.Label {
                        text: blueValue
                        textFormat: Text.PlainText
                    }
                }

                PlasmaComponents3.Slider {
                    id: blueControl
                    Layout.fillWidth: true
                    from: 0
                    to: 255
                    stepSize: 1
                    value: root.blueValue

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
            border.width: 1
            border.color: Kirigami.Theme.textColor
            radius: 4

            PlasmaComponents3.Label {
                anchors.centerIn: parent
                text: i18n("Color Preview")
                color: (redValue + greenValue + blueValue > 384) ? "#000000" : "#FFFFFF"
            }
        }
    }
}
