#!/bin/bash

# WizControl Log Filter Script
# Monitors both journalctl and current plasmashell logs for WizControl-specific output

echo "=== WizControl Log Monitor ==="
echo "This script filters logs for WizControl-related output only"
echo "Press Ctrl+C to stop monitoring"
echo ""

# Function to filter WizControl logs
filter_wizcontrol_logs() {
    grep -i "wizcontrol\|wizbridge\|wiz.*control\|bulb.*control\|node.*wizController" --line-buffered --color=always
}

# Start monitoring logs
echo "Starting log monitoring..."
echo "=================================="

# Monitor both journalctl and current logs
{
    # Monitor journalctl for plasmashell logs
    journalctl -f -u plasma-plasmashell.service --since "5 minutes ago" 2>/dev/null &
    
    # Monitor current plasmashell process logs if available
    if pgrep plasmashell > /dev/null; then
        # Try to get current plasmashell logs from systemd user session
        journalctl --user -f _COMM=plasmashell --since "5 minutes ago" 2>/dev/null &
    fi
    
    # Wait for background processes
    wait
} | filter_wizcontrol_logs

echo ""
echo "Log monitoring stopped."
echo ""
echo "To restart plasma and monitor logs from scratch:"
echo "  systemctl --user restart plasma-plasmashell"
echo "  ./debug-logs.sh"
