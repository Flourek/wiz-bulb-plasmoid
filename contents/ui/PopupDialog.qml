/*
    SPDX-FileCopyrightText: 2011 Viranch Mehta <viranch.mehta@gmail.com>
    SPDX-FileCopyrightText: 2013-2016 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2023-2024 Natalie Clarius <natalie.clarius@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

PlasmaExtras.Representation {
    id: dialog

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

            Repeater {
                id: screenBrightnessRepeater
                model: screenBrightnessControl.displays

                property Item firstSlider: screenBrightnessRepeater.itemAt(0)
                property Item lastSlider: screenBrightnessRepeater.itemAt(count - 1)

                BrightnessItem {
                    id: screenBrightnessSlider

                    required property int index
                    required property string displayName
                    required property string label
                    required property int brightness
                    required property int maxBrightness

                    property Item previousSlider: screenBrightnessRepeater.itemAt(index - 1)
                    property Item nextSlider: screenBrightnessRepeater.itemAt(index + 1)

                    width: scrollView.availableWidth

                    icon.name: "video-display-brightness"
                    text: label
                    type: BrightnessItem.Type.Screen
                    value: brightness
                    minimumValue: 0
                    maximumValue: maxBrightness

                    KeyNavigation.up: previousSlider ?? dialog.KeyNavigation.up
                    KeyNavigation.down: nextSlider ?? firstItemAfterScreenBrightnessRepeater
                    KeyNavigation.backtab: previousSlider ?? dialog.KeyNavigation.backtab
                    KeyNavigation.tab: KeyNavigation.down

                    stepSize: maxBrightness/100

                    onMoved: {
                        screenBrightnessControl.setBrightness(displayName, value);
                        appletInterface.notifyValueChange("brightness", (value / maxBrightness) * 100);
                    }
                    onActiveFocusChanged: if (activeFocus) scrollView.positionViewAtItem(this)
                }

                // itemAt() doesn't cause bindings to be updated when the underlying items change,
                // so let's do it by ourselves
                onItemAdded: (index, item) => {
                    if (index == 0) {
                        firstSlider = item;
                    }
                    if (index > 0) {
                        itemAt(index - 1).nextSlider = item;
                    }
                    if (index + 1 < count) {
                        itemAt(index + 1).previousSlider = item;
                    }
                    if (index + 1 == count) {
                        lastSlider = item;
                    }
                }
                onItemRemoved: (index, item) => {
                    if (item == firstSlider) {
                        firstSlider = itemAt(0);
                    }
                    if (index > 0) {
                        itemAt(index - 1).nextSlider = itemAt(index);
                    }
                    if (index + 1 < count) {
                        itemAt(index + 1).previousSlider = itemAt(index);
                    }
                    if (item == lastSlider) {
                        lastSlider = itemAt(count - 1);
                    }
                }
            }

            BrightnessItem {
                id: keyboardBrightnessSlider

                width: scrollView.availableWidth

                icon.name: "input-keyboard-brightness"
                text: i18n("Keyboard Backlight")
                type: BrightnessItem.Type.Keyboard
                value: keyboardBrightnessControl.brightness
                maximumValue: keyboardBrightnessControl.brightnessMax
                visible: keyboardBrightnessControl.isBrightnessAvailable

                KeyNavigation.up: screenBrightnessRepeater.lastSlider ?? dialog.KeyNavigation.up
                KeyNavigation.down: wizBrightnessSlider.visible ? wizBrightnessSlider : rgbColorItem
                KeyNavigation.backtab: KeyNavigation.up
                KeyNavigation.tab: KeyNavigation.down

                onMoved: {
                    keyboardBrightnessControl.brightness = value;
                    appletInterface.notifyValueChange("brightness", (value / maximumValue) * 100);
                }
                onActiveFocusChanged: if (activeFocus) scrollView.positionViewAtItem(this)

                // Manually dragging the slider around breaks the binding
                Connections {
                    target: keyboardBrightnessControl
                    function onBrightnessChanged() {
                        keyboardBrightnessSlider.value = keyboardBrightnessControl.brightness;
                    }
                }
            }

            BrightnessItem {
                id: wizBrightnessSlider

                width: scrollView.availableWidth

                icon.name: "network-wireless"
                text: {
                    if (!appletInterface.wizInitialDiscoveryComplete || appletInterface.wizDiscovering) {
                        return i18n("WiZ Bulb (Discovering...)");
                    } else if (appletInterface.wizConnected) {
                        return i18n("WiZ Bulb Brightness");
                    } else {
                        return i18n("WiZ Bulb (Disconnected)");
                    }
                }
                type: BrightnessItem.Type.Screen
                value: appletInterface.wizBrightness
                maximumValue: 100
                visible: true
                enabled: appletInterface.wizConnected

                KeyNavigation.up: keyboardBrightnessSlider.visible ? keyboardBrightnessSlider : (screenBrightnessRepeater.lastSlider ?? dialog.KeyNavigation.up)
                KeyNavigation.down: rgbColorItem
                KeyNavigation.backtab: KeyNavigation.up
                KeyNavigation.tab: KeyNavigation.down

                onMoved: {
                    if (appletInterface.wizConnected) {
                        appletInterface.wizBrightness = value;
                        appletInterface.notifyValueChange("wizBrightness", value);
                    }
                }
                onActiveFocusChanged: if (activeFocus) scrollView.positionViewAtItem(this)

                // Update slider when brightness changes
                Connections {
                    target: appletInterface
                    function onWizBrightnessChanged() {
                        wizBrightnessSlider.value = appletInterface.wizBrightness;
                    }
                }
            }

            RGBItem {
                id: rgbColorItem

                width: scrollView.availableWidth

                redValue: appletInterface.redValue
                greenValue: appletInterface.greenValue
                blueValue: appletInterface.blueValue

                KeyNavigation.up: wizBrightnessSlider.visible ? wizBrightnessSlider : (keyboardBrightnessSlider.visible ? keyboardBrightnessSlider : keyboardBrightnessSlider.KeyNavigation.up)
                KeyNavigation.backtab: KeyNavigation.up

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

        }
    }
}

