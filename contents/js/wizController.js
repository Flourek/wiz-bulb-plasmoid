// WiZ Bulb Controller Bridge for QML
// This module provides an interface between QML and the Wikari library

const fs = require('fs');
const path = require('path');

// Import wikari from node_modules
let wikari;
try {
    wikari = require('./node_modules/wikari');
} catch (e) {
    console.error('Failed to import wikari:', e);
    process.exit(1);
}

const { discover, SCENES } = wikari;

class WizBulbController {
    constructor() {
        this.bulbs = [];
        this.currentBulb = null;
        this.isDiscovering = false;
    }

    // Discovery method
    async discoverBulbs() {
        if (this.isDiscovering) {
            return { success: false, message: "Discovery already in progress" };
        }

        this.isDiscovering = true;
        try {
            console.error("Starting bulb discovery...");
            let discoveredBulbs = [];
            
            // Try different network ranges - we know 192.168.0.255 works from testing
            const networkOptions = [
                { addr: '192.168.0.255', waitMs: 8000 },  // Your working network
                { addr: '192.168.1.255', waitMs: 5000 },  // Wikari default
                { addr: '255.255.255.255', waitMs: 5000 } // Global broadcast
            ];
            
            for (const options of networkOptions) {
                if (discoveredBulbs.length > 0) break;
                
                console.error(`Trying discovery with ${options.addr}...`);
                try {
                    discoveredBulbs = await discover(options);
                    if (discoveredBulbs.length > 0) {
                        console.error(`Found bulbs using ${options.addr}`);
                        break;
                    }
                } catch (e) {
                    console.error(`Discovery with ${options.addr} failed:`, e.message);
                }
            }
            
            this.bulbs = discoveredBulbs;
            if (this.bulbs.length > 0) {
                this.currentBulb = this.bulbs[0];
                console.error(`Found ${this.bulbs.length} bulb(s)`);
                console.error("Full bulb object:", JSON.stringify(this.bulbs[0], null, 2));
                console.error("Bulb properties:", Object.keys(this.bulbs[0]));
                
                // Try to extract useful info from the bulb
                const bulbInfo = this.bulbs.map(b => {
                    const info = {};
                    // Use the correct property names from Wikari
                    info.ip = b.address || b.ip || 'unknown';
                    info.mac = b.macIdentifier || b.mac || 'unknown';
                    info.port = b.bulbPort || 38899;
                    return info;
                });
                
                console.error("Bulb details:", bulbInfo);
                return { 
                    success: true, 
                    count: this.bulbs.length, 
                    bulbs: bulbInfo
                };
            } else {
                console.error("No bulbs found after all attempts");
                return { success: false, message: "No bulbs found" };
            }
        } catch (error) {
            console.error("Discovery error:", error);
            return { success: false, message: error.message };
        } finally {
            this.isDiscovering = false;
        }
    }

    // Get current bulb state
    async getBulbState() {
        if (!this.currentBulb) {
            return { success: false, message: "No bulb connected" };
        }

        try {
            const pilot = await this.currentBulb.getPilot();
            return { success: true, state: pilot };
        } catch (error) {
            console.error("Error getting bulb state:", error);
            return { success: false, message: error.message };
        }
    }

    // Set brightness (0-100)
    async setBrightness(brightness) {
        if (!this.currentBulb) {
            return { success: false, message: "No bulb connected" };
        }

        try {
            await this.currentBulb.brightness(brightness);
            return { success: true, brightness: brightness };
        } catch (error) {
            console.error("Error setting brightness:", error);
            return { success: false, message: error.message };
        }
    }

    // Set RGB color
    async setRGBColor(red, green, blue) {
        if (!this.currentBulb) {
            return { success: false, message: "No bulb connected" };
        }

        try {
            // Convert RGB to hex
            const hex = `#${red.toString(16).padStart(2, '0')}${green.toString(16).padStart(2, '0')}${blue.toString(16).padStart(2, '0')}`;
            await this.currentBulb.color(hex);
            return { success: true, color: { red, green, blue, hex } };
        } catch (error) {
            console.error("Error setting RGB color:", error);
            return { success: false, message: error.message };
        }
    }

    // Turn bulb on/off
    async setBulbPower(on) {
        if (!this.currentBulb) {
            return { success: false, message: "No bulb connected" };
        }

        try {
            await this.currentBulb.turn(on);
            return { success: true, power: on };
        } catch (error) {
            console.error("Error setting bulb power:", error);
            return { success: false, message: error.message };
        }
    }

    // Close connection
    closeBulbConnection() {
        if (this.currentBulb) {
            try {
                this.currentBulb.closeConnection();
                return { success: true };
            } catch (error) {
                console.error("Error closing connection:", error);
                return { success: false, message: error.message };
            }
        }
        return { success: true };
    }

    // Get available scenes
    getAvailableScenes() {
        return { success: true, scenes: Object.keys(SCENES) };
    }

    // Set scene
    async setScene(sceneName) {
        if (!this.currentBulb) {
            return { success: false, message: "No bulb connected" };
        }

        if (!SCENES[sceneName]) {
            return { success: false, message: "Scene not found" };
        }

        try {
            await this.currentBulb.scene(SCENES[sceneName]);
            return { success: true, scene: sceneName };
        } catch (error) {
            console.error("Error setting scene:", error);
            return { success: false, message: error.message };
        }
    }
}

// Main execution function
async function main() {
    const args = process.argv.slice(2);
    if (args.length === 0) {
        console.error('No command provided');
        process.exit(1);
    }

    const controller = new WizBulbController();
    const command = args[0];
    let result;

    try {
        switch (command) {
            case 'discover':
                result = await controller.discoverBulbs();
                break;
            case 'getState':
                result = await controller.getBulbState();
                break;
            case 'setBrightness':
                const brightness = parseInt(args[1]);
                result = await controller.setBrightness(brightness);
                break;
            case 'setRGB':
                const red = parseInt(args[1]);
                const green = parseInt(args[2]);
                const blue = parseInt(args[3]);
                result = await controller.setRGBColor(red, green, blue);
                break;
            case 'setPower':
                const power = args[1] === 'true';
                result = await controller.setBulbPower(power);
                break;
            case 'getScenes':
                result = controller.getAvailableScenes();
                break;
            case 'setScene':
                result = await controller.setScene(args[1]);
                break;
            case 'close':
                result = controller.closeBulbConnection();
                break;
            case 'discoverAndGetState':
                // First discover, then get state
                const discoverResult = await controller.discoverBulbs();
                if (discoverResult.success && controller.currentBulb) {
                    const stateResult = await controller.getBulbState();
                    result = {
                        success: true,
                        discovery: discoverResult,
                        state: stateResult
                    };
                } else {
                    result = discoverResult;
                }
                break;
            default:
                result = { success: false, message: 'Unknown command' };
        }

        // Output result as JSON
        console.log(JSON.stringify(result));
    } catch (error) {
        console.log(JSON.stringify({ success: false, message: error.message }));
    }

    // Always try to close connection before exit
    controller.closeBulbConnection();
}

// Run if called directly
if (require.main === module) {
    main();
}

module.exports = WizBulbController;
