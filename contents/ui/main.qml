/*
    SPDX-FileCopyrightText: 2011 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2011 Viranch Mehta <viranch.mehta@gmail.com>
    SPDX-FileCopyrightText: 2013-2015 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2021-2022 ivan tkachenko <me@ratijas.tk>
    SPDX-FileCopyrightText: 2024 Natalie Clarius <natalie.clarius@kde.org

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.coreaddons as KCoreAddons
import org.kde.kcmutils // KCMLauncher
import org.kde.config // KAuthorized
import org.kde.notification
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.plasma5support as Plasma5Support

import org.kde.plasma.private.brightnesscontrolplugin

PlasmoidItem {
    id: brightnessAndColorControl

    readonly property bool inPanel: (Plasmoid.location === PlasmaCore.Types.TopEdge
        || Plasmoid.location === PlasmaCore.Types.RightEdge
        || Plasmoid.location === PlasmaCore.Types.BottomEdge
        || Plasmoid.location === PlasmaCore.Types.LeftEdge)

    ScreenBrightnessControl {
        id: screenBrightnessControl
        isSilent: brightnessAndColorControl.expanded
    }
    KeyboardBrightnessControl {
        id: keyboardBrightnessControl
        isSilent: brightnessAndColorControl.expanded
    }

    // WiZ Bulb Controller - Direct UDP implementation
    WizController {
        id: wizBridge
        
        Component.onCompleted: {
            console.log("[WizControl] WizController component loaded");
            console.log("[WizControl] Initial state - isConnected:", isConnected, "isDiscovering:", isDiscovering);
        }
        
        onErrorOccurred: function(message) {
            valueNotification.text = i18n("WiZ Error: %1", message);
            valueNotification.sendEvent();
        }
        
        onConnectionChanged: function(connected) {
            wizInitialDiscoveryComplete = true;
            if (connected) {
                valueNotification.text = i18n("WiZ bulb connected (%1 bulb(s))", bulbCount);
                valueNotification.sendEvent();
                // Get initial state
                getBulbState();
                getAvailableScenes();
            } else {
                valueNotification.text = i18n("WiZ bulb disconnected");
                valueNotification.sendEvent();
            }
        }

        onOperationCompleted: function(operation, success, data) {
            if (success && operation === "setBrightness") {
                // Update brightness value from bulb response
                if (data && data.brightness !== undefined) {
                    wizBrightness = data.brightness;
                }
            }
        }

        // Get current bulb state
        function getBulbState() {
            if (!isConnected) {
                error("No bulb connected");
                return;
            }

            executeCommand("getState", [], function(exitCode, stdout, stderr) {
                if (exitCode === 0 && stdout) {
                    try {
                        const result = JSON.parse(stdout.trim());
                        if (result.success) {
                            bulbState = result.state;
                            stateReceived(result.state);
                            operationCompleted("getState", true, result);
                        } else {
                            error(result.message || "Failed to get bulb state");
                            operationCompleted("getState", false, result);
                        }
                    } catch (e) {
                        error("Failed to parse state result: " + e.message);
                        operationCompleted("getState", false, null);
                    }
                } else {
                    error("Get state process failed: " + stderr);
                    operationCompleted("getState", false, null);
                }
            });
        }
    }

    // WiZ-specific properties
    property int wizBrightness: 50
    property bool wizConnected: wizBridge.isConnected
    property bool wizDiscovering: wizBridge.isDiscovering
    property bool wizInitialDiscoveryComplete: false
    property var wizScenes: wizBridge.availableScenes
    property bool bulbPowerState: true // Default to ON state

    // RGB Color properties
    property int redValue: 255
    property int greenValue: 255
    property int blueValue: 255

    // Notification for value changes
    Notification {
        id: valueNotification
        componentName: "plasma_workspace"
        eventId: "colorChanged"
        title: i18n("Wiz Control")
        urgency: Notification.LowUrgency
    }

    function notifyValueChange(type, value) {
        if (type === "brightness") {
            valueNotification.text = i18n("Brightness: %1%", Math.round(value));
        } else if (type === "wizBrightness") {
            valueNotification.text = i18n("WiZ Brightness: %1%", Math.round(value));
            wizBridge.setBrightness(Math.round(value));
        } else if (type === "red") {
            valueNotification.text = i18n("Red: %1", Math.round(value));
            wizBridge.setRGBColor(Math.round(value), greenValue, blueValue);
        } else if (type === "green") {
            valueNotification.text = i18n("Green: %1", Math.round(value));
            wizBridge.setRGBColor(redValue, Math.round(value), blueValue);
        } else if (type === "blue") {
            valueNotification.text = i18n("Blue: %1", Math.round(value));
            wizBridge.setRGBColor(redValue, greenValue, Math.round(value));
        }
        valueNotification.sendEvent();
    }

    property int keyboardBrightnessPercent: keyboardBrightnessControl.brightnessMax ? Math.round(100 * keyboardBrightnessControl.brightness / keyboardBrightnessControl.brightnessMax) : 0

    function symbolicizeIconName(iconName) {
        const symbolicSuffix = "-symbolic";
        if (iconName.endsWith(symbolicSuffix)) {
            return iconName;
        }

        return iconName + symbolicSuffix;
    }

    switchWidth: Kirigami.Units.gridUnit * 10
    switchHeight: Kirigami.Units.gridUnit * 10

    Plasmoid.title: i18n("Brightness & RGB Control")

    LayoutMirroring.enabled: Qt.application.layoutDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    Plasmoid.status: {
        return screenBrightnessControl.isBrightnessAvailable || keyboardBrightnessControl.isBrightnessAvailable ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus;
    }

    // QAbstractItemModel doesn't provide bindable properties for QML, let's make sure
    // toolTipMainText gets updated anyway by (re)setting a variable used in the binding
    Connections {
        id: displayModelConnections
        target: screenBrightnessControl.displays
        property var screenBrightnessInfo: []

        function update() {
            const [labelRole, brightnessRole, maxBrightnessRole] = ["label", "brightness", "maxBrightness"].map(
                (roleName) => target.KItemModels.KRoleNames.role(roleName));

            screenBrightnessInfo = [...Array(target.rowCount()).keys()].map((i) => { // for each display index
                const modelIndex = target.index(i, 0);
                return {
                    label: target.data(modelIndex, labelRole),
                    brightness: target.data(modelIndex, brightnessRole),
                    maxBrightness: target.data(modelIndex, maxBrightnessRole),
                };
            });
        }
        function onDataChanged() { update(); }
        function onModelReset() { update(); }
        function onRowsInserted() { update(); }
        function onRowsMoved() { update(); }
        function onRowsRemoved() { update(); }
    }
    toolTipMainText: {
        const parts = [];
        for (const screen of displayModelConnections.screenBrightnessInfo) {
            const brightnessPercent = screen.maxBrightness ? Math.round(100 * screen.brightness / screen.maxBrightness) : 0
            const text = displayModelConnections.screenBrightnessInfo.length === 1
                ? i18n("Screen brightness at %1%", brightnessPercent)
                : i18nc("Brightness of named display at percentage", "Brightness of %1 at %2%", screen.label, brightnessPercent);
            parts.push(text);
        }

        if (keyboardBrightnessControl.isBrightnessAvailable) {
            parts.push(i18n("Keyboard brightness at %1%", keyboardBrightnessPercent));
        }

        parts.push(i18n("RGB: R:%1 G:%2 B:%3", redValue, greenValue, blueValue));

        return parts.join("\n");
    }
    Connections {
        target: screenBrightnessControl
    }

    // Connections to keep RGB values synchronized
    onRedValueChanged: if (fullRepresentation && fullRepresentation.rgbColorItem) fullRepresentation.rgbColorItem.redValue = redValue
    onGreenValueChanged: if (fullRepresentation && fullRepresentation.rgbColorItem) fullRepresentation.rgbColorItem.greenValue = greenValue
    onBlueValueChanged: if (fullRepresentation && fullRepresentation.rgbColorItem) fullRepresentation.rgbColorItem.blueValue = blueValue

    toolTipSubText: {
        const parts = [];
        if (screenBrightnessControl.isBrightnessAvailable) {
            parts.push(i18n("Scroll to adjust screen brightness"));
        }
        parts.push(i18n("Left-click to open controls"));
        return parts.join("\n");
    }

    Plasmoid.icon: {
        let iconName = "im-jabber";

        if (inPanel) {
            return symbolicizeIconName(iconName);
        }

        return iconName;
    }

    compactRepresentation: CompactRepresentation {

        onWheel: wheel => {
            if (!screenBrightnessControl.isBrightnessAvailable) {
                return;
            }
            const delta = (wheel.inverted ? -1 : 1) * (wheel.angleDelta.y ? wheel.angleDelta.y : -wheel.angleDelta.x);

            if (Math.abs(delta) < 120) {
                // Touchpad scrolling
                screenBrightnessControl.adjustBrightnessRatio((delta/120) * 0.05);
            } else if (wheel.modifiers & Qt.ShiftModifier) {
                // Discrete/wheel scrolling - round to next small step (e.g. percentage point)
                screenBrightnessControl.adjustBrightnessStep(
                    delta < 0 ? ScreenBrightnessControl.DecreaseSmall : ScreenBrightnessControl.IncreaseSmall);
            } else {
                // Discrete/wheel scrolling - round to next large step (e.g. 5%, 10%)
                screenBrightnessControl.adjustBrightnessStep(
                    delta < 0 ? ScreenBrightnessControl.Decrease : ScreenBrightnessControl.Increase);
            }
        }

        acceptedButtons: Qt.LeftButton
        property bool wasExpanded: false
        onPressed: wasExpanded = brightnessAndColorControl.expanded
        onClicked: mouse => {
            brightnessAndColorControl.expanded = !wasExpanded;
        }
    }

    fullRepresentation: PlasmaExtras.Representation {
        id: dialogItem

        readonly property var appletInterface: brightnessAndColorControl
        property var rgbColorItem: null

        Layout.minimumWidth: Kirigami.Units.gridUnit * 10
        Layout.maximumWidth: Kirigami.Units.gridUnit * 80
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20

        readonly property Item firstItemAfterScreenBrightnessRepeater: keyboardBrightnessSlider.visible ? keyboardBrightnessSlider : (wizBrightnessSlider.visible ? wizBrightnessSlider : rgbColorItem)
        KeyNavigation.down: screenBrightnessRepeater.firstSlider ?? firstItemAfterScreenBrightnessRepeater

        contentItem: PlasmaComponents3.ScrollView {
            id: scrollView

            focus: false

            function positionViewAtItem(item) {
                if (!PlasmaComponents3.ScrollBar.vertical.visible) {
                    return;
                }
                const rect = brightnessList.mapFromItem(item, 0, 0, item.width, item.height);
                if (rect.y < scrollView.contentItem.contentY) {
                    scrollView.contentItem.contentY = rect.y;
                } else if (rect.y + rect.height > scrollView.contentItem.contentY + scrollView.height) {
                    scrollView.contentItem.contentY = rect.y + rect.height - scrollView.height;
                }
            }

            Column {
                id: brightnessList

                spacing: Kirigami.Units.smallSpacing * 2

                
                
                // Warm White Controls (moved to top)
                WarmWhiteItem {
                    id: warmWhiteItem
                    width: scrollView.availableWidth
                    enabled: appletInterface.wizConnected
                }

                // RGB Controls
                RGBItem {
                    id: rgbColorItem
                    width: scrollView.availableWidth

                    redValue: appletInterface.redValue
                    greenValue: appletInterface.greenValue
                    blueValue: appletInterface.blueValue

                    onColorChanged: (channel, value) => {
                        if (channel === "red") {
                            appletInterface.redValue = value;
                        } else if (channel === "green") {
                            appletInterface.greenValue = value;
                        } else if (channel === "blue") {
                            appletInterface.blueValue = value;
                        }
                        appletInterface.notifyValueChange(channel, value);
                    }

                    Component.onCompleted: {
                        if (parent && parent.parent && parent.parent.rgbColorItem !== undefined) {
                            parent.parent.rgbColorItem = rgbColorItem;
                        }
                    }
                }

                // Scene Controls (moved to bottom)
                SceneItem {
                    id: sceneItem
                    width: scrollView.availableWidth
                    enabled: appletInterface.wizConnected
                    availableScenes: appletInterface.wizScenes
                }

                // Include all the existing content from PopupDialog here...
                // Restart Button
                PlasmaComponents3.Button {
                    id: restartButton
                    width: scrollView.availableWidth
                    text: i18n("🔄 Restart WiZ Control")
                    icon.name: "view-refresh"
                    
                    onClicked: {
                        console.log("[WizControl] Restart button clicked");
                        
                        // Reset all states
                        appletInterface.wizConnected = false;
                        appletInterface.wizScenes = [];
                        
                        // Clear the cache
                        wizBridge.clearCache();
                        
                        // Restart discovery
                        wizBridge.discoverBulbs();
                        
                        // Visual feedback
                        text = i18n("🔄 Restarting...");
                        enabled = false;
                        
                        // Re-enable after 2 seconds
                        restartTimer.start();
                    }
                    
                    // Timer to re-enable button after restart
                    Timer {
                        id: restartTimer
                        interval: 2000
                        repeat: false
                        onTriggered: {
                            restartButton.text = i18n("🔄 Restart WiZ Control");
                            restartButton.enabled = true;
                        }
                    }
                }
            }
        }

        Layout.minimumHeight: Kirigami.Units.gridUnit * 10
        Layout.maximumHeight: Kirigami.Units.gridUnit * 40
        Layout.preferredHeight: implicitHeight

    }

    // Remove configure action - applet's config is empty, and it also handles
    // brightness; replacing with configureNightLight is inappropriate
    Component.onCompleted: {
        console.log("[WizControl] Plasmoid starting up...");
        Plasmoid.removeInternalAction("configure");
        
        // Auto-discover WiZ bulbs at startup
        console.log("[WizControl] Starting auto-discovery...");
        wizBridge.discoverBulbs();
    }
}
