/*
    SPDX-FileCopyrightText: 2024 Wiz Control Developer

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.components as PlasmaComponents3

QtObject {
    id: wizBridge

    property bool isConnected: false
    property bool isDiscovering: false
    property int bulbCount: 0
    property var bulbState: null
    property var availableScenes: []

    signal bulbDiscovered(var bulbs)
    signal stateReceived(var state)
    signal errorOccurred(string message)
    signal connectionChanged(bool connected)
    signal operationCompleted(string operation, bool success, var data)

    // Execute Node.js command
    function executeCommand(command, args, callback) {
        if (!args) args = [];
        
        // Get the plasmoid directory path properly  
        const plasmoidPath = Qt.resolvedUrl("../js").toString().replace("file://", "");
        const fullCommand = `cd "${plasmoidPath}" && node wizController.js ${command} ${args.join(' ')} 2>&1`;
        
        console.log("[WizControl] Executing:", fullCommand);
        
        const process = Qt.createQmlObject(`
            import QtQuick
            import org.kde.plasma.plasma5support as Plasma5Support
            
            Plasma5Support.DataSource {
                id: executable
                engine: "executable"
                connectedSources: []
                
                function exec(cmd) {
                    console.log("[WizControl] Connecting to source:", cmd);
                    connectSource(cmd);
                }
                
                onNewData: {
                    var exitCode = data["exit code"];
                    var exitStatus = data["exit status"];
                    var stdout = data["stdout"];
                    var stderr = data["stderr"];
                    
                    console.log("[WizControl] Command completed. Exit code:", exitCode);
                    if (stdout) console.log("[WizControl] stdout:", stdout);
                    if (stderr) console.log("[WizControl] stderr:", stderr);
                    
                    disconnectSource(sourceName);
                    
                    if (callback) {
                        callback(exitCode, stdout, stderr);
                    }
                }
            }
        `, wizBridge);

        process.exec(fullCommand);
    }

    // Discover WiZ bulbs
    function discoverBulbs() {
        if (isDiscovering) return;
        
        isDiscovering = true;
        executeCommand("discoverAndGetState", [], function(exitCode, stdout, stderr) {
            isDiscovering = false;
            
            if (exitCode === 0 && stdout) {
                try {
                    // The JSON result should be on stdout, debug info goes to stderr
                    // First try to parse the entire stdout as JSON
                    let jsonString = stdout.trim();
                    let result = null;
                    
                    try {
                        result = JSON.parse(jsonString);
                    } catch (e) {
                        // If that fails, look for a JSON line in the output
                        const lines = stdout.split('\n');
                        for (let line of lines) {
                            line = line.trim();
                            if (line.startsWith('{"success"') || line.startsWith('{"')) {
                                try {
                                    result = JSON.parse(line);
                                    jsonString = line;
                                    break;
                                } catch (parseError) {
                                    // Continue looking for valid JSON
                                }
                            }
                        }
                    }
                    
                    if (result) {
                        console.log("[WizControl] Successfully parsed JSON result");
                        if (result.success && result.discovery && result.discovery.success) {
                        bulbCount = result.discovery.count;
                        isConnected = result.discovery.count > 0;
                        
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
                        errorOccurred(message);
                        operationCompleted("discover", false, result);
                    }
                } else {
                    console.log("[WizControl] No valid JSON found in command output");
                    errorOccurred("No valid JSON found in command output");
                    operationCompleted("discover", false, null);
                }
                } catch (e) {
                    console.log("[WizControl] JSON parse error:", e.message);
                    errorOccurred("Failed to parse discovery result: " + e.message);
                    operationCompleted("discover", false, null);
                }
            } else {
                errorOccurred("Discovery process failed: " + stderr);
                operationCompleted("discover", false, null);
            }
        });
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
                errorOccurred("Get state process failed: " + stderr);
                operationCompleted("getState", false, null);
            }
        });
    }

    // Set bulb brightness (0-100)
    function setBrightness(brightness) {
        if (!isConnected) {
            errorOccurred("No bulb connected");
            return;
        }

        brightness = Math.max(0, Math.min(100, brightness));
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
                errorOccurred("Set brightness process failed: " + stderr);
                operationCompleted("setBrightness", false, null);
            }
        });
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
                errorOccurred("Set RGB process failed: " + stderr);
                operationCompleted("setRGB", false, null);
            }
        });
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
                errorOccurred("Set power process failed: " + stderr);
                operationCompleted("setPower", false, null);
            }
        });
    }

    // Get available scenes
    function getAvailableScenes() {
        executeCommand("getScenes", [], function(exitCode, stdout, stderr) {
            if (exitCode === 0 && stdout) {
                try {
                    const result = JSON.parse(stdout.trim());
                    if (result.success) {
                        availableScenes = result.scenes;
                        operationCompleted("getScenes", true, result);
                    } else {
                        errorOccurred(result.message || "Failed to get scenes");
                        operationCompleted("getScenes", false, result);
                    }
                } catch (e) {
                    errorOccurred("Failed to parse scenes result: " + e.message);
                    operationCompleted("getScenes", false, null);
                }
            } else {
                errorOccurred("Get scenes process failed: " + stderr);
                operationCompleted("getScenes", false, null);
            }
        });
    }

    // Set scene
    function setScene(sceneName) {
        if (!isConnected) {
            errorOccurred("No bulb connected");
            return;
        }

        executeCommand("setScene", [sceneName], function(exitCode, stdout, stderr) {
            if (exitCode === 0 && stdout) {
                try {
                    const result = JSON.parse(stdout.trim());
                    operationCompleted("setScene", result.success, result);
                    if (!result.success) {
                        errorOccurred(result.message || "Failed to set scene");
                    }
                } catch (e) {
                    errorOccurred("Failed to parse scene result: " + e.message);
                    operationCompleted("setScene", false, null);
                }
            } else {
                errorOccurred("Set scene process failed: " + stderr);
                operationCompleted("setScene", false, null);
            }
        });
    }

    // Close bulb connection
    function closeBulbConnection() {
        executeCommand("close", [], function(exitCode, stdout, stderr) {
            isConnected = false;
            connectionChanged(false);
            operationCompleted("close", true, null);
        });
    }
}
