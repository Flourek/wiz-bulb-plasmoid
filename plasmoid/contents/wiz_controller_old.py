#!/usr/bin/env python3
"""
Simple WiZ Bulb Controller
Direct UDP communication without external dependencies
"""

import socket
import json
import sys
import time
import argparse
import os
import tempfile

class WizController:
    def __init__(self):
        self.bulb_ip = None
        self.bulb_port = 38899
        self.cache_file = os.path.join(tempfile.gettempdir(), "wiz_bulb_cache.json")
        self._load_cached_bulb()
        
    def discover_bulbs(self):
        """Discover WiZ bulbs on the network"""
        discovery_message = {
            "method": "registration",
            "params": {
                "phoneMac": "AAAAAAAAAAAA",
                "register": False,
                "phoneIp": "1.2.3.4",
                "id": 1
            }
        }
        
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        sock.settimeout(8.0)
        
        message = json.dumps(discovery_message).encode()
        bulbs = []
        
        # Try different broadcast addresses
        broadcast_addresses = ["192.168.0.255", "192.168.1.255", "255.255.255.255"]
        
        try:
            for addr in broadcast_addresses:
                try:
                    sock.sendto(message, (addr, 38899))
                except Exception as e:
                    continue
            
            # Listen for responses
            start_time = time.time()
            while time.time() - start_time < 8.0:
                try:
                    data, addr = sock.recvfrom(1024)
                    response = json.loads(data.decode())
                    
                    if response.get("method") == "registration" and response.get("result", {}).get("mac"):
                        bulb = {
                            "ip": addr[0],
                            "port": addr[1],
                            "mac": response["result"]["mac"]
                        }
                        
                        # Check if already found this bulb
                        if not any(b["mac"] == bulb["mac"] for b in bulbs):
                            bulbs.append(bulb)
                            
                except socket.timeout:
                    break
                except Exception:
                    continue
                    
        finally:
            sock.close()
            
        if bulbs:
            self.bulb_ip = bulbs[0]["ip"]
            self.bulb_port = bulbs[0]["port"] 
            # Cache the discovered bulb
            self._save_cached_bulb(self.bulb_ip, self.bulb_port)
            return {"success": True, "bulbs": bulbs}
        else:
            return {"success": False, "message": "No bulbs found"}
    
    def send_command(self, command):
        """Send a command to the bulb"""
        if not self.bulb_ip:
            # Try to discover if not connected
            discover_result = self.discover_bulbs()
            if not discover_result["success"]:
                return {"success": False, "message": "No bulb found"}
        
        # Try to send command with current IP
        result = self._send_command_direct(command)
        
        # If command failed, try rediscovering once
        if not result["success"] and "timeout" in result["message"].lower():
            self._clear_cache()
            discover_result = self.discover_bulbs()
            if discover_result["success"]:
                result = self._send_command_direct(command)
        
        return result
    
    def _send_command_direct(self, command):
        """Send command directly to bulb without discovery fallback"""
        if not self.bulb_ip:
            return {"success": False, "message": "No bulb IP available"}
            
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.settimeout(5.0)
        
        try:
            message = json.dumps(command).encode()
            sock.sendto(message, (self.bulb_ip, self.bulb_port))
            
            data, addr = sock.recvfrom(1024)
            response = json.loads(data.decode())
            return {"success": True, "response": response}
            
        except Exception as e:
            return {"success": False, "message": str(e)}
        finally:
            sock.close()
    
    def get_state(self):
        """Get current bulb state"""
        result = self.send_command({"method": "getPilot", "params": {}})
        if result["success"] and "result" in result["response"]:
            return {"success": True, "state": result["response"]["result"]}
        return result
    
    def set_brightness(self, brightness):
        """Set bulb brightness (0-100)"""
        brightness = min(100, int(brightness))
        result = self.send_command({
            "method": "setPilot",
            "params": {"dimming": brightness}
        })
        return result
    
    def set_rgb(self, red, green, blue):
        """Set RGB color (0-255 each)"""
        red = max(0, min(255, int(red)))
        green = max(0, min(255, int(green)))
        blue = max(0, min(255, int(blue)))
        
        result = self.send_command({
            "method": "setPilot",
            "params": {"r": red, "g": green, "b": blue}
        })
        return result
    
    def set_power(self, on):
        """Set bulb power on/off"""
        result = self.send_command({
            "method": "setPilot",
            "params": {"state": bool(on)}
        })
        return result
    
    def set_temperature(self, temp):
        """Set color temperature (2200-6500K)"""
        temp = max(2200, min(6500, int(temp)))
        result = self.send_command({
            "method": "setPilot",
            "params": {"temp": temp}
        })
        return result
    
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
                        self.bulb_port = cache_data.get('port', 38899)
                        # Quick ping test to see if bulb is still reachable
                        if self._test_bulb_connection():
                            return
                        else:
                            # Bulb not reachable, clear cache
                            self._clear_cache()
        except Exception:
            pass  # Ignore cache errors, will discover fresh
    
    def _save_cached_bulb(self, ip, port=38899):
        """Save bulb IP to cache file"""
        try:
            cache_data = {
                'ip': ip,
                'port': port,
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
    
    def _test_bulb_connection(self):
        """Quick test to see if cached bulb is still reachable"""
        if not self.bulb_ip:
            return False
        
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            sock.settimeout(2.0)  # Short timeout for quick test
            
            test_command = {"method": "getPilot", "params": {}}
            message = json.dumps(test_command).encode()
            sock.sendto(message, (self.bulb_ip, self.bulb_port))
            
            data, addr = sock.recvfrom(1024)
            response = json.loads(data.decode())
            sock.close()
            
            return response.get("result") is not None
        except Exception:
            return False
        
def main():
    parser = argparse.ArgumentParser(description='WiZ Bulb Controller')
    parser.add_argument('command', help='Command to execute')
    parser.add_argument('args', nargs='*', help='Command arguments')
    
    args = parser.parse_args()
    controller = WizController()
    
    try:
        if args.command == "discover":
            result = controller.discover_bulbs()
            
        elif args.command == "discoverAndGetState":
            discover_result = controller.discover_bulbs()
            if discover_result["success"]:
                state_result = controller.get_state()
                result = {
                    "success": True,
                    "discovery": discover_result,
                    "state": state_result
                }
            else:
                result = discover_result
                
        elif args.command == "getState":
            result = controller.get_state()
            
        elif args.command == "setBrightness":
            if len(args.args) < 1:
                result = {"success": False, "message": "Brightness value required"}
            else:
                result = controller.set_brightness(args.args[0])
                
        elif args.command == "setRGB":
            if len(args.args) < 3:
                result = {"success": False, "message": "Red, green, blue values required"}
            else:
                result = controller.set_rgb(args.args[0], args.args[1], args.args[2])
                
        elif args.command == "setPower":
            if len(args.args) < 1:
                result = {"success": False, "message": "Power state required"}
            else:
                power = args.args[0].lower() in ('true', '1', 'on', 'yes')
                result = controller.set_power(power)
                
        elif args.command == "setTemp":
            if len(args.args) < 1:
                result = {"success": False, "message": "Temperature value required"}
            else:
                result = controller.set_temperature(args.args[0])
                
        else:
            result = {"success": False, "message": f"Unknown command: {args.command}"}
            
        print(json.dumps(result))
        
    except Exception as e:
        print(json.dumps({"success": False, "message": str(e)}))

if __name__ == "__main__":
    main()
