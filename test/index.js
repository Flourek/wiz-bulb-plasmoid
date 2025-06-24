import { discover, SCENES } from "wikari";

console.log("Starting WiZ bulb discovery and testing...");

try {
    console.log("Discovering bulbs...");
    
    // Try different network ranges since default might not work
    const networkRanges = [
        { addr: '192.168.0.255', waitMs: 5000 },  // Your network
        { addr: '192.168.1.255', waitMs: 5000 },  // Default
        { addr: '255.255.255.255', waitMs: 5000 } // Broadcast
    ];
    
    let bulbs = [];
    for (const options of networkRanges) {
        if (bulbs.length > 0) break;
        
        console.log(`Trying discovery with ${options.addr}...`);
        try {
            bulbs = await discover(options);
            if (bulbs.length > 0) {
                console.log(`Found bulbs using ${options.addr}`);
                break;
            }
        } catch (e) {
            console.log(`Discovery with ${options.addr} failed:`, e.message);
        }
    }

    console.log(`Found ${bulbs.length} bulb(s)`);
    
    if (bulbs.length > 0) {
        console.log("Bulb details:", bulbs.map((b, i) => ({
            index: i,
            address: b.address,
            macIdentifier: b.macIdentifier,
            bulbPort: b.bulbPort,
            listenPort: b.listenPort
        })));
    }

    const bulb = bulbs[0];

    if (!bulb) {
        console.log("No bulbs found!");
        process.exit(0);
    }

    console.log("\n=== Testing bulb functionality ===");

    // get the current state of the bulb
    // WiZ calls the bulb state "pilot"
    // so you have "setPilot" and "getPilot"
    console.log("Getting current pilot state...");
    const currentState = await bulb.getPilot();
    console.log("Current state:", JSON.stringify(currentState, null, 2));

    // whenever the bulb sends a message, log it to the console
    console.log("Setting up message listener...");
    bulb.onMessage((message) => {
        console.log("Bulb message:", message);
    });

    // turn the bulb on
    console.log("Turning bulb ON...");
    await bulb.turn(true);
    await sleep(1000);

    // set the color to red
    console.log("Setting color to red (#f44336)...");
    await bulb.color("#f44336");
    await sleep(2000);

    // set the color to some cool and some warm white
    console.log("Setting to cool and warm white (c: 40, w: 40)...");
    await bulb.color({ c: 40, w: 40 });
    await sleep(2000);

    // set the scene to "TV Time"
    console.log("Setting scene to 'TV Time'...");
    if (SCENES["TV Time"]) {
        await bulb.scene(SCENES["TV Time"]);
        await sleep(2000);
    } else {
        console.log("TV Time scene not available, available scenes:", Object.keys(SCENES));
    }

    // set the bulb to 10_000K white
    console.log("Setting to 10,000K white...");
    await bulb.white(10_000);
    await sleep(2000);

    // set the bulb brightness to 40%
    console.log("Setting brightness to 40%...");
    await bulb.brightness(40);
    await sleep(2000);

    // toggle the bulb (turns it off since it was already on)
    console.log("Toggling bulb (should turn off)...");
    await bulb.toggle();
    await sleep(2000);

    // turn back on
    console.log("Turning bulb back ON...");
    await bulb.turn(true);
    
    console.log("Closing connection...");
    bulb.closeConnection();
    
    console.log("\n=== Test completed successfully! ===");

} catch (error) {
    console.error("Error during testing:", error);
    process.exit(1);
}

// Helper function for delays
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}