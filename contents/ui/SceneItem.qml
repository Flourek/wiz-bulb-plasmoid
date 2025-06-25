/*
    SPDX-FileCopyrightText: 2024 Wiz Control Developer
    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: sceneItem
    
    property bool enabled: true
    property var availableScenes: []
    property alias sceneSpeed: speedSlider.value
    
    spacing: Kirigami.Units.smallSpacing
    
    // Scene Label
    PlasmaComponents3.Label {
        text: i18n("Scene Control")
        font.weight: Font.DemiBold
        font.family: "monospace"
        Layout.alignment: Qt.AlignHCenter
    }
    
    // Scene Speed Control
    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        
        PlasmaComponents3.Label {
            text: "SPD:"
            font.family: "monospace"
            font.bold: true
            color: "#FFFFFF"
        }
        
        PlasmaComponents3.Slider {
            id: speedSlider
            Layout.fillWidth: true
            from: 1
            to: 20
            value: 10
            enabled: sceneItem.enabled
            
            handle: Rectangle {
                x: speedSlider.leftPadding + speedSlider.visualPosition * (speedSlider.availableWidth - width)
                y: speedSlider.topPadding + speedSlider.availableHeight / 2 - height / 2
                implicitWidth: 20
                implicitHeight: 20
                radius: 10
                color: "#FFFFFF"
                border.color: "#444444"
                border.width: 2
            }
            
            background: Rectangle {
                x: speedSlider.leftPadding
                y: speedSlider.topPadding + speedSlider.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 6
                width: speedSlider.availableWidth
                height: implicitHeight
                radius: 3
                color: "#FFFFFF"
                border.color: "#444444"
                border.width: 1
            }
        }
        
        PlasmaComponents3.Label {
            text: Math.round(speedSlider.value).toString().padStart(2, '0')
            Layout.minimumWidth: Kirigami.Units.gridUnit * 1.5
            horizontalAlignment: Text.AlignHCenter
            font.family: "monospace"
            font.bold: true
            color: "#FFFFFF"
        }
    }
    
    // Static default scenes (always available)
    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        
        PlasmaComponents3.Button {
            text: "NORMAL"
            Layout.fillWidth: true
            enabled: sceneItem.enabled
            font.family: "monospace"
            onClicked: wizBridge.setWarmWhite(80, 4000) // Neutral white
        }
        
        PlasmaComponents3.Button {
            text: "NIGHT"
            Layout.fillWidth: true
            enabled: sceneItem.enabled
            font.family: "monospace"
            onClicked: wizBridge.setWarmWhite(20, 2200) // Dim warm
        }
        
        PlasmaComponents3.Button {
            text: "READ"
            Layout.fillWidth: true
            enabled: sceneItem.enabled
            font.family: "monospace"
            onClicked: wizBridge.setWarmWhite(90, 5000) // Bright cool
        }
        
        PlasmaComponents3.Button {
            text: "SLEEP"
            Layout.fillWidth: true
            enabled: sceneItem.enabled
            font.family: "monospace"
            onClicked: wizBridge.setWarmWhite(10, 2200) // Very dim warm
        }
    }
    
    // Popular WiZ scenes
    GridLayout {
        Layout.fillWidth: true
        columns: 3
        rowSpacing: Kirigami.Units.smallSpacing
        columnSpacing: Kirigami.Units.smallSpacing
        
        PlasmaComponents3.Button {
            text: "OCEAN"
            Layout.fillWidth: true
            enabled: sceneItem.enabled
            font.family: "monospace"
            onClicked: wizBridge.setSceneWithSpeed(1, Math.round(speedSlider.value))
        }
        
        PlasmaComponents3.Button {
            text: "ROMANCE"
            Layout.fillWidth: true
            enabled: sceneItem.enabled
            font.family: "monospace"
            onClicked: wizBridge.setSceneWithSpeed(2, Math.round(speedSlider.value))
        }
        
        PlasmaComponents3.Button {
            text: "SUNSET"
            Layout.fillWidth: true
            enabled: sceneItem.enabled
            font.family: "monospace"
            onClicked: wizBridge.setSceneWithSpeed(3, Math.round(speedSlider.value))
        }
        
        PlasmaComponents3.Button {
            text: "PARTY"
            Layout.fillWidth: true
            enabled: sceneItem.enabled
            font.family: "monospace"
            onClicked: wizBridge.setSceneWithSpeed(4, Math.round(speedSlider.value))
        }
        
        PlasmaComponents3.Button {
            text: "FIRE"
            Layout.fillWidth: true
            enabled: sceneItem.enabled
            font.family: "monospace"
            onClicked: wizBridge.setSceneWithSpeed(5, Math.round(speedSlider.value))
        }
        
        PlasmaComponents3.Button {
            text: "COZY"
            Layout.fillWidth: true
            enabled: sceneItem.enabled
            font.family: "monospace"
            onClicked: wizBridge.setSceneWithSpeed(6, Math.round(speedSlider.value))
        }
        
        PlasmaComponents3.Button {
            text: "FOREST"
            Layout.fillWidth: true
            enabled: sceneItem.enabled
            font.family: "monospace"
            onClicked: wizBridge.setSceneWithSpeed(7, Math.round(speedSlider.value))
        }
        
        PlasmaComponents3.Button {
            text: "PASTEL"
            Layout.fillWidth: true
            enabled: sceneItem.enabled
            font.family: "monospace"
            onClicked: wizBridge.setSceneWithSpeed(8, Math.round(speedSlider.value))
        }
        
        PlasmaComponents3.Button {
            text: "DAYLIGHT"
            Layout.fillWidth: true
            enabled: sceneItem.enabled
            font.family: "monospace"
            onClicked: wizBridge.setSceneWithSpeed(12, Math.round(speedSlider.value))
        }
    }
    
    // All scenes dropdown
    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        
        PlasmaComponents3.Label {
            text: i18n("ALL:")
            font.family: "monospace"
            font.bold: true
        }
        
        PlasmaComponents3.ComboBox {
            id: sceneComboBox
            Layout.fillWidth: true
            enabled: sceneItem.enabled
            font.family: "monospace"
            
            function updateModel() {
                var scenes = [i18n("SELECT SCENE...")];
                for (var i = 0; i < availableScenes.length; i++) {
                    scenes.push(availableScenes[i].name.toUpperCase());
                }
                model = scenes;
            }
            
            Component.onCompleted: updateModel()
            
            Connections {
                target: sceneItem
                function onAvailableScenesChanged() {
                    sceneComboBox.updateModel();
                }
            }
            
            onActivated: function(index) {
                if (index > 0 && index <= availableScenes.length) {
                    var scene = availableScenes[index - 1];
                    wizBridge.setSceneWithSpeed(scene.id, Math.round(speedSlider.value));
                    // Reset to "Select scene..." after selection
                    currentIndex = 0;
                }
            }
        }
    }
}
