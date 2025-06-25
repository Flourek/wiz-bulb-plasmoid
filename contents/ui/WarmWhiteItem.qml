/*
    SPDX-FileCopyrightText: 2024 Wiz Control Developer
    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: warmWhiteItem
    
    property alias warmBrightness: warmBrightnessSlider.value
    property alias warmTemperature: warmTempSlider.value
    property bool enabled: true
    
    spacing: Kirigami.Units.smallSpacing
    
    // Warm White Label
    PlasmaComponents3.Label {
        text: i18n("Warm White Control")
        font.weight: Font.DemiBold
        font.family: "monospace"
        Layout.alignment: Qt.AlignHCenter
    }
    
    // Brightness Control
    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        
        Kirigami.Icon {
            source: "brightness-low"
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: Kirigami.Units.iconSizes.small
        }
        
        PlasmaComponents3.Slider {
            id: warmBrightnessSlider
            Layout.fillWidth: true
            from: 10
            to: 100
            value: 50
            enabled: warmWhiteItem.enabled
            
            onMoved: {
                if (enabled) {
                    wizBridge.setWarmWhite(Math.round(value), Math.round(warmTempSlider.value));
                }
            }
        }
        
        Kirigami.Icon {
            source: "brightness-high"
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: Kirigami.Units.iconSizes.small
        }
        
        PlasmaComponents3.Label {
            text: Math.round(warmBrightnessSlider.value).toString().padStart(3, '0') + "%"
            Layout.minimumWidth: Kirigami.Units.gridUnit * 2
            horizontalAlignment: Text.AlignHCenter
            font.family: "monospace"
            font.bold: true
        }
    }
    
    // Temperature Control (Hot to Cold)
    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        
        PlasmaComponents3.Label {
            text: "HOT"
            font.pixelSize: Kirigami.Units.fontMetrics.font.pixelSize
            color: "#ff6b35"
            font.family: "monospace"
            font.bold: true
        }
        
        PlasmaComponents3.Slider {
            id: warmTempSlider
            Layout.fillWidth: true
            from: 2200
            to: 6500
            value: 3000
            enabled: warmWhiteItem.enabled
            
            // Visual feedback - warmer colors on left, cooler on right
            background: Rectangle {
                width: warmTempSlider.availableWidth
                height: 6
                radius: 3
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#ff6b35" }
                    GradientStop { position: 0.5; color: "#ffd700" }
                    GradientStop { position: 1.0; color: "#87ceeb" }
                }
                border.color: "#444444"
                border.width: 1
            }
            
            onMoved: {
                if (enabled) {
                    wizBridge.setWarmWhite(Math.round(warmBrightnessSlider.value), Math.round(value));
                }
            }
        }
        
        PlasmaComponents3.Label {
            text: "COLD"
            font.pixelSize: Kirigami.Units.fontMetrics.font.pixelSize
            color: "#87ceeb"
            font.family: "monospace"
            font.bold: true
        }
        
        PlasmaComponents3.Label {
            text: Math.round(warmTempSlider.value).toString().padStart(4, '0') + "K"
            Layout.minimumWidth: Kirigami.Units.gridUnit * 2.5
            horizontalAlignment: Text.AlignHCenter
            font.family: "monospace"
            font.bold: true
        }
    }
    
    // Quick temperature presets
    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        
        PlasmaComponents3.Button {
            text: "CANDLE"
            Layout.fillWidth: true
            enabled: warmWhiteItem.enabled
            font.family: "monospace"
            onClicked: {
                warmTempSlider.value = 2200;
                wizBridge.setWarmWhite(Math.round(warmBrightnessSlider.value), 2200);
            }
        }
        
        PlasmaComponents3.Button {
            text: "WARM"
            Layout.fillWidth: true
            enabled: warmWhiteItem.enabled
            font.family: "monospace"
            onClicked: {
                warmTempSlider.value = 3000;
                wizBridge.setWarmWhite(Math.round(warmBrightnessSlider.value), 3000);
            }
        }
        
        // Row layout for COOL button and ON/OFF button
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            
            PlasmaComponents3.Button {
                text: "COOL"
                Layout.fillWidth: true
                enabled: warmWhiteItem.enabled
                font.family: "monospace"
                onClicked: {
                    warmTempSlider.value = 6500;
                    wizBridge.setWarmWhite(Math.round(warmBrightnessSlider.value), 6500);
                }
            }
            
            PlasmaComponents3.Button {
                id: powerButton
                text: appletInterface.wizConnected && appletInterface.bulbPowerState ? "OFF" : "ON"
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                enabled: warmWhiteItem.enabled
                font.family: "monospace"
                font.bold: true
                
                // Color coding: green for ON, red for OFF
                background: Rectangle {
                    color: powerButton.pressed ? 
                           (appletInterface.wizConnected && appletInterface.bulbPowerState ? "#AA4444" : "#44AA44") :
                           (appletInterface.wizConnected && appletInterface.bulbPowerState ? "#CC5555" : "#55CC55")
                    border.color: "#888888"
                    border.width: 1
                    radius: 4
                }
                
                onClicked: {
                    var newState = !(appletInterface.wizConnected && appletInterface.bulbPowerState);
                    wizBridge.setBulbPower(newState);
                    appletInterface.bulbPowerState = newState;
                }
            }
        }
    }
}
