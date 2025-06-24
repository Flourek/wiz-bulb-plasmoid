#!/bin/bash
# Quick test script for WizControl plasmoid

echo "🔧 WizControl Plasmoid Test Script"
echo "=================================="

echo ""
echo "1️⃣  Testing Node.js controller directly:"
cd /home/flourek/.local/share/plasma/plasmoids/org.kde.plasma.wizcontrol/contents/js
echo "   📍 Current directory: $(pwd)"

echo ""
echo "2️⃣  Testing discovery command:"
node wizController.js discoverAndGetState | jq . 2>/dev/null || node wizController.js discoverAndGetState

echo ""
echo "3️⃣  Testing path resolution for QML:"
echo "   📁 QML path would resolve to: $(cd ../ui && echo $(pwd)/../js)"

echo ""
echo "4️⃣  Checking plasmoid files:"
echo "   📄 main.qml: $(ls -la ../ui/main.qml 2>/dev/null && echo "✅ Found" || echo "❌ Missing")"
echo "   📄 WizBridge.qml: $(ls -la ../ui/WizBridge.qml 2>/dev/null && echo "✅ Found" || echo "❌ Missing")"
echo "   📄 wizController.js: $(ls -la wizController.js 2>/dev/null && echo "✅ Found" || echo "❌ Missing")"

echo ""
echo "5️⃣  Testing if plasmashell is running:"
if pgrep plasmashell > /dev/null; then
    echo "   ✅ plasmashell is running"
else
    echo "   ❌ plasmashell is not running"
fi

echo ""
echo "🏁 Test completed!"
echo ""
echo "💡 To debug plasmoid issues:"
echo "   • Run: ./debug-logs.sh"
echo "   • Or check: journalctl --user -f | grep -i wiz"
