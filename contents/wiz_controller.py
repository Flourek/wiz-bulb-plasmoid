#!/usr/bin/env python3
"""
WiZ Bulb Controller using pywizlight
Supports RGB, brightness, warm light, and scenes
"""

import asyncio
import json
import sys
import argparse
import os
import tempfile
import time

# Add local lib directory to path for bundled pywizlight
lib_path = os.path.join(os.path.dirname(__file__), 'lib')
sys.path.insert(0, lib_path)

try:
    from pywizlight import wizlight, PilotBuilder, discovery
except ImportError:
    print(json.dumps({"success": False, "message": "pywizlight not available in local lib directory"}))
    sys.exit(1)

class WizController:
    def __init__(self):
        self.bulb_ip = None
        self.light = None
        self.cache_file = os.path.join(tempfile.gettempdir(), "wiz_bulb_cache.json")
        self._load_cached_bulb()
        
    def _load_cached_bulb(self):
        """Load cached bulb IP from file"""
        try:
            if os.path.exists(self.cache_file):
                with open(self.cache_file, 'r') as f:
                    cache_data = json.load(f)
                    # Check if cache is recent (less than 1 hour old)
                    cache_time = cache_data.get('timestamp', 0)
                    if time.time() - cache_time < 3600:  # 1 hour
                        self.bulb_ip = cache_data.get('ip')
                        if self.bulb_ip:
                            self.light = wizlight(self.bulb_ip)
        except Exception:
            pass  # Ignore cache errors, will discover fresh
    
    def _save_cached_bulb(self, ip):
        """Save bulb IP to cache file"""
        try:
            cache_data = {
                'ip': ip,
                'timestamp': time.time()
            }
            with open(self.cache_file, 'w') as f:
                json.dump(cache_data, f)
        except Exception:
            pass  # Ignore cache save errors
    
    def _clear_cache(self):
        """Clear the cache file"""
        try:
            if os.path.exists(self.cache_file):
                os.remove(self.cache_file)
        except Exception:
            pass

    async def discover_bulbs(self):
        """Discover WiZ bulbs on the network"""
        try:
            bulbs = await discovery.discover_lights(broadcast_space="192.168.0.255")
            
            if not bulbs:
                # Try other broadcast addresses
                for addr in ["192.168.1.255", "255.255.255.255"]:
                    bulbs = await discovery.discover_lights(broadcast_space=addr)
                    if bulbs:
                        break
            
            if bulbs:
                bulb_list = []
                for bulb in bulbs:
                    bulb_list.append({
                        "ip": bulb.ip,
                        "mac": bulb.mac,
                        "port": 38899
                    })
                
                # Use first bulb and cache it
                self.bulb_ip = bulbs[0].ip
                self.light = wizlight(self.bulb_ip)
                self._save_cached_bulb(self.bulb_ip)
                
                return {"success": True, "bulbs": bulb_list}
            else:
                return {"success": False, "message": "No bulbs found"}
                
        except Exception as e:
            return {"success": False, "message": str(e)}

    async def ensure_connected(self):
        """Ensure we have a connection to a bulb"""
        if not self.light:
            result = await self.discover_bulbs()
            if not result["success"]:
                return False
        return True

    async def get_state(self):
        """Get current bulb state"""
        try:
            if not await self.ensure_connected():
                return {"success": False, "message": "No bulb found"}
            
            state = await self.light.updateState()
            return {
                "success": True, 
                "state": {
                    "state": state.get_state(),
                    "brightness": state.get_brightness(),
                    "rgb": state.get_rgb(),
                    "colortemp": state.get_colortemp(),
                    "scene": state.get_scene()
                }
            }
        except Exception as e:
            return {"success": False, "message": str(e)}

    async def set_brightness(self, brightness):
        """Set bulb brightness (10-100)"""
        try:
            if not await self.ensure_connected():
                return {"success": False, "message": "No bulb found"}
            
            brightness = max(10, min(100, int(brightness)))
            await self.light.turn_on(PilotBuilder(brightness=brightness))
            return {"success": True, "response": {"result": {"success": True}}}
        except Exception as e:
            return {"success": False, "message": str(e)}

    async def set_rgb(self, red, green, blue):
        """Set RGB color (0-255 each)"""
        try:
            if not await self.ensure_connected():
                return {"success": False, "message": "No bulb found"}
            
            red = max(0, min(255, int(red)))
            green = max(0, min(255, int(green)))
            blue = max(0, min(255, int(blue)))
            
            await self.light.turn_on(PilotBuilder(rgb=(red, green, blue)))
            return {"success": True, "response": {"result": {"success": True}}}
        except Exception as e:
            return {"success": False, "message": str(e)}

    async def set_warm_white(self, brightness, temp):
        """Set warm white with brightness (10-100) and temperature (2200-6500K)"""
        try:
            if not await self.ensure_connected():
                return {"success": False, "message": "No bulb found"}
            
            brightness = max(10, min(100, int(brightness)))
            temp = max(2200, min(6500, int(temp)))
            
            await self.light.turn_on(PilotBuilder(brightness=brightness, colortemp=temp))
            return {"success": True, "response": {"result": {"success": True}}}
        except Exception as e:
            return {"success": False, "message": str(e)}

    async def set_color_temp(self, temp):
        """Set color temperature (2200-6500K)"""
        try:
            if not await self.ensure_connected():
                return {"success": False, "message": "No bulb found"}
            
            temp = max(2200, min(6500, int(temp)))
            await self.light.turn_on(PilotBuilder(colortemp=temp))
            return {"success": True, "response": {"result": {"success": True}}}
        except Exception as e:
            return {"success": False, "message": str(e)}

    async def set_scene(self, scene_id):
        """Set scene (1-32)"""
        try:
            if not await self.ensure_connected():
                return {"success": False, "message": "No bulb found"}
            
            scene_id = max(1, min(32, int(scene_id)))
            await self.light.turn_on(PilotBuilder(scene=scene_id))
            return {"success": True, "response": {"result": {"success": True}}}
        except Exception as e:
            return {"success": False, "message": str(e)}

    async def set_scene_with_speed(self, scene_id, speed):
        """Set scene with speed (1-20, higher = faster)"""
        try:
            if not await self.ensure_connected():
                return {"success": False, "message": "No bulb found"}
            
            scene_id = max(1, min(32, int(scene_id)))
            speed = max(1, min(20, int(speed)))
            
            await self.light.turn_on(PilotBuilder(scene=scene_id, speed=speed))
            return {"success": True, "response": {"result": {"success": True}}}
        except Exception as e:
            return {"success": False, "message": str(e)}

    async def set_power(self, on):
        """Set bulb power on/off"""
        try:
            if not await self.ensure_connected():
                return {"success": False, "message": "No bulb found"}
            
            if on:
                await self.light.turn_on(PilotBuilder())
            else:
                await self.light.turn_off()
            return {"success": True, "response": {"result": {"success": True}}}
        except Exception as e:
            return {"success": False, "message": str(e)}

    async def get_scenes(self):
        """Get available scene list"""
        scenes = [
            {"id": 1, "name": "Ocean"},
            {"id": 2, "name": "Romance"}, 
            {"id": 3, "name": "Sunset"},
            {"id": 4, "name": "Party"},
            {"id": 5, "name": "Fireplace"},
            {"id": 6, "name": "Cozy"},
            {"id": 7, "name": "Forest"},
            {"id": 8, "name": "Pastel Colors"},
            {"id": 9, "name": "Wake up"},
            {"id": 10, "name": "Bedtime"},
            {"id": 11, "name": "Warm White"},
            {"id": 12, "name": "Daylight"},
            {"id": 13, "name": "Cool white"},
            {"id": 14, "name": "Night light"},
            {"id": 15, "name": "Focus"},
            {"id": 16, "name": "Relax"},
            {"id": 17, "name": "True colors"},
            {"id": 18, "name": "TV time"},
            {"id": 19, "name": "Plant growth"},
            {"id": 20, "name": "Spring"},
            {"id": 21, "name": "Summer"},
            {"id": 22, "name": "Fall"},
            {"id": 23, "name": "Deep dive"},
            {"id": 24, "name": "Jungle"},
            {"id": 25, "name": "Mojito"},
            {"id": 26, "name": "Club"},
            {"id": 27, "name": "Christmas"},
            {"id": 28, "name": "Halloween"},
            {"id": 29, "name": "Candlelight"},
            {"id": 30, "name": "Golden white"},
            {"id": 31, "name": "Pulse"},
            {"id": 32, "name": "Steampunk"}
        ]
        return {"success": True, "scenes": scenes}

async def main():
    parser = argparse.ArgumentParser(description='WiZ Bulb Controller')
    parser.add_argument('command', help='Command to execute')
    parser.add_argument('args', nargs='*', help='Command arguments')
    
    args = parser.parse_args()
    controller = WizController()
    
    try:
        if args.command == "discover":
            result = await controller.discover_bulbs()
            
        elif args.command == "discoverAndGetState":
            discover_result = await controller.discover_bulbs()
            if discover_result["success"]:
                state_result = await controller.get_state()
                result = {
                    "success": True,
                    "discovery": discover_result,
                    "state": state_result
                }
            else:
                result = discover_result
                
        elif args.command == "getState":
            result = await controller.get_state()
            
        elif args.command == "setBrightness":
            if len(args.args) < 1:
                result = {"success": False, "message": "Brightness value required"}
            else:
                result = await controller.set_brightness(args.args[0])
                
        elif args.command == "setRGB":
            if len(args.args) < 3:
                result = {"success": False, "message": "Red, green, blue values required"}
            else:
                result = await controller.set_rgb(args.args[0], args.args[1], args.args[2])
                
        elif args.command == "setWarmWhite":
            if len(args.args) < 2:
                result = {"success": False, "message": "Brightness and temperature values required"}
            else:
                result = await controller.set_warm_white(args.args[0], args.args[1])
                
        elif args.command == "setColorTemp":
            if len(args.args) < 1:
                result = {"success": False, "message": "Temperature value required"}
            else:
                result = await controller.set_color_temp(args.args[0])
                
        elif args.command == "setScene":
            if len(args.args) < 1:
                result = {"success": False, "message": "Scene ID required"}
            else:
                result = await controller.set_scene(args.args[0])
                
        elif args.command == "setSceneWithSpeed":
            if len(args.args) < 2:
                result = {"success": False, "message": "Scene ID and speed required"}
            else:
                result = await controller.set_scene_with_speed(args.args[0], args.args[1])
                
        elif args.command == "setPower":
            if len(args.args) < 1:
                result = {"success": False, "message": "Power state required"}
            else:
                power = args.args[0].lower() in ('true', '1', 'on', 'yes')
                result = await controller.set_power(power)
                
        elif args.command == "getScenes":
            result = await controller.get_scenes()
            
        elif args.command == "clearCache":
            controller._clear_cache()
            # Reset the controller state
            controller.bulb_ip = None
            controller.light = None
            result = {"success": True, "message": "Cache cleared successfully"}
                
        else:
            result = {"success": False, "message": f"Unknown command: {args.command}"}
            
        print(json.dumps(result))
        
    except Exception as e:
        print(json.dumps({"success": False, "message": str(e)}))

if __name__ == "__main__":
    asyncio.run(main())
