/*
    SPDX-FileCopyrightText: 2024 Wiz Control Developer
    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: wizController

    property bool isConnected: false
    property bool isDiscovering: false
    property int bulbCount: 0
    property var bulbState: null
    property var discoveredBulbs: []
    property var availableScenes: []

    // Throttling timers to prevent spam
    property var lastBrightnessValue: -1
    property var lastRGBValues: [-1, -1, -1]
    
    Timer {
        id: brightnessThrottleTimer
        interval: 100  // 100ms throttle
        repeat: false
        onTriggered: {
            if (lastBrightnessValue >= 0) {
                _setBrightnessNow(lastBrightnessValue)
                lastBrightnessValue = -1
            }
        }
    }
    
    Timer {
        id: rgbThrottleTimer
        interval: 100  // 100ms throttle  
        repeat: false
        onTriggered: {
            if (lastRGBValues[0] >= 0) {
                _setRGBColorNow(lastRGBValues[0], lastRGBValues[1], lastRGBValues[2])
                lastRGBValues = [-1, -1, -1]
            }
        }
    }

    signal bulbDiscovered(var bulbs)
    signal stateReceived(var state)
    signal errorOccurred(string message)
    signal connectionChanged(bool connected)
    signal operationCompleted(string operation, bool success, var data)

    // DataSource for executing Python commands
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        
        property var pendingCallback: null
        property string pendingOperation: ""
        
        onNewData: function(sourceName, data) {
            var exitCode = data["exit code"];
            var stdout = data["stdout"];
            var stderr = data["stderr"];
            
            disconnectSource(sourceName);
            
            if (pendingCallback) {
                pendingCallback(exitCode, stdout, stderr);
                pendingCallback = null;
                pendingOperation = "";
            }
        }
    }

    // Execute Python command
    function executeCommand(command, args, callback, operation) {
        if (!args) args = [];
        
        const plasmoidPath = Qt.resolvedUrl("..").toString().replace("file://", "");
        const pythonScript = `${plasmoidPath}/wiz_controller.py`;
        const fullCommand = `python3 "${pythonScript}" ${command} ${args.join(' ')}`;
        
        console.log("[WizControl] Executing:", fullCommand);
        
        executable.pendingCallback = callback;
        executable.pendingOperation = operation || command;
        executable.connectSource(fullCommand);
    }

    // Discover WiZ bulbs
    function discoverBulbs() {
        if (isDiscovering) return;
        
        console.log("[WizControl] Starting bulb discovery...");
        isDiscovering = true;
        
        executeCommand("discoverAndGetState", [], function(exitCode, stdout, stderr) {
            isDiscovering = false;
            
            if (exitCode === 0 && stdout) {
                try {
                    const result = JSON.parse(stdout.trim());
                    if (result.success && result.discovery && result.discovery.success) {
                        bulbCount = result.discovery.bulbs.length;
                        isConnected = bulbCount > 0;
                        discoveredBulbs = result.discovery.bulbs;
                        
                        console.log("[WizControl] Discovery successful! Found", bulbCount, "bulb(s)");
                        
                        // Also get the initial state if available
                        if (result.state && result.state.success) {
                            bulbState = result.state.state;
                            stateReceived(result.state.state);
                        }
                        
                        bulbDiscovered(result.discovery.bulbs);
                        connectionChanged(isConnected);
                        operationCompleted("discover", true, result);
                    } else {
                        const message = result.discovery ? result.discovery.message : (result.message || "Discovery failed");
                        console.log("[WizControl] Discovery failed:", message);
                        errorOccurred(message);
                        operationCompleted("discover", false, result);
                    }
                } catch (e) {
                    console.log("[WizControl] JSON parse error:", e.message);
                    errorOccurred("Failed to parse discovery result: " + e.message);
                    operationCompleted("discover", false, null);
                }
            } else {
                console.log("[WizControl] Command failed with exit code:", exitCode, "stderr:", stderr);
                errorOccurred("Discovery process failed: " + (stderr || "Unknown error"));
                operationCompleted("discover", false, null);
            }
        }, "discover");
    }

    // Get current bulb state
    function getBulbState() {
        if (!isConnected) {
            errorOccurred("No bulb connected");
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
                        errorOccurred(result.message || "Failed to get bulb state");
                        operationCompleted("getState", false, result);
                    }
                } catch (e) {
                    errorOccurred("Failed to parse state result: " + e.message);
                    operationCompleted("getState", false, null);
                }
            } else {
                errorOccurred("Get state process failed: " + (stderr || "Unknown error"));
                operationCompleted("getState", false, null);
            }
        }, "getState");
    }

    // Set bulb brightness (10-100)
    function setBrightness(brightness) {
        if (!isConnected) {
            errorOccurred("No bulb connected");
            return;
        }

        brightness = Math.max(10, Math.min(100, brightness));
        console.log("[WizControl] Setting brightness to:", brightness);
        
        // Throttle the actual command execution
        lastBrightnessValue = brightness;
        brightnessThrottleTimer.start();
    }

    // Immediately set brightness (for internal use)
    function _setBrightnessNow(brightness) {
        if (!isConnected) {
            errorOccurred("No bulb connected");
            return;
        }

        console.log("[WizControl] Setting brightness to (immediate):", brightness);
        
        executeCommand("setBrightness", [brightness.toString()], function(exitCode, stdout, stderr) {
            if (exitCode === 0 && stdout) {
                try {
                    const result = JSON.parse(stdout.trim());
                    operationCompleted("setBrightness", result.success, result);
                    if (!result.success) {
                        errorOccurred(result.message || "Failed to set brightness");
                    }
                } catch (e) {
                    errorOccurred("Failed to parse brightness result: " + e.message);
                    operationCompleted("setBrightness", false, null);
                }
            } else {
                errorOccurred("Set brightness process failed: " + (stderr || "Unknown error"));
                operationCompleted("setBrightness", false, null);
            }
        }, "setBrightness");
    }

    // Set RGB color (0-255 each)
    function setRGBColor(red, green, blue) {
        if (!isConnected) {
            errorOccurred("No bulb connected");
            return;
        }

        red = Math.max(0, Math.min(255, red));
        green = Math.max(0, Math.min(255, green));
        blue = Math.max(0, Math.min(255, blue));

        console.log("[WizControl] Setting RGB color to:", red, green, blue);
        
        // Throttle the actual command execution
        lastRGBValues = [red, green, blue];
        rgbThrottleTimer.start();
    }

    // Immediately set RGB color (for internal use)
    function _setRGBColorNow(red, green, blue) {
        if (!isConnected) {
            errorOccurred("No bulb connected");
            return;
        }

        console.log("[WizControl] Setting RGB color to (immediate):", red, green, blue);
        
        executeCommand("setRGB", [red.toString(), green.toString(), blue.toString()], function(exitCode, stdout, stderr) {
            if (exitCode === 0 && stdout) {
                try {
                    const result = JSON.parse(stdout.trim());
                    operationCompleted("setRGB", result.success, result);
                    if (!result.success) {
                        errorOccurred(result.message || "Failed to set RGB color");
                    }
                } catch (e) {
                    errorOccurred("Failed to parse RGB result: " + e.message);
                    operationCompleted("setRGB", false, null);
                }
            } else {
                errorOccurred("Set RGB process failed: " + (stderr || "Unknown error"));
                operationCompleted("setRGB", false, null);
            }
        }, "setRGB");
    }

    // Set bulb power
    function setBulbPower(on) {
        if (!isConnected) {
            errorOccurred("No bulb connected");
            return;
        }

        executeCommand("setPower", [on ? "true" : "false"], function(exitCode, stdout, stderr) {
            if (exitCode === 0 && stdout) {
                try {
                    const result = JSON.parse(stdout.trim());
                    operationCompleted("setPower", result.success, result);
                    if (!result.success) {
                        errorOccurred(result.message || "Failed to set bulb power");
                    }
                } catch (e) {
                    errorOccurred("Failed to parse power result: " + e.message);
                    operationCompleted("setPower", false, null);
                }
            } else {
                errorOccurred("Set power process failed: " + (stderr || "Unknown error"));
                operationCompleted("setPower", false, null);
            }
        }, "setPower");
    }

    // Set color temperature
    function setColorTemperature(temp) {
        if (!isConnected) {
            errorOccurred("No bulb connected");
            return;
        }

        executeCommand("setTemp", [temp.toString()], function(exitCode, stdout, stderr) {
            if (exitCode === 0 && stdout) {
                try {
                    const result = JSON.parse(stdout.trim());
                    operationCompleted("setColorTemp", result.success, result);
                    if (!result.success) {
                        errorOccurred(result.message || "Failed to set color temperature");
                    }
                } catch (e) {
                    errorOccurred("Failed to parse temperature result: " + e.message);
                    operationCompleted("setColorTemp", false, null);
                }
            } else {
                errorOccurred("Set temperature process failed: " + (stderr || "Unknown error"));
                operationCompleted("setColorTemp", false, null);
            }
        }, "setColorTemp");
    }
}
