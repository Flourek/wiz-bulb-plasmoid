#!/bin/bash
# WizControl log filter - monitors plasmashell output for WizControl messages

echo "🔍 Monitoring plasmashell logs for WizControl activity..."
echo "📝 Look for lines containing '[WizControl]'"
echo "🛑 Press Ctrl+C to stop"
echo ""

# Kill any existing plasmashell and restart with logging
killall plasmashell 2>/dev/null

# Start plasmashell in background and filter its output
plasmashell 2>&1 | grep --line-buffered -E "\[WizControl\]|wizcontrol|WizBridge|TypeError.*file.*function" | while read line; do
    timestamp=$(date "+%H:%M:%S")
    echo "[$timestamp] $line"
done
