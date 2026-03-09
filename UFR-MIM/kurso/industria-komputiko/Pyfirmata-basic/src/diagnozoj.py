#!/usr/bin/env python3

from pyfirmata2 import ArduinoMega
import time

PORT = "/dev/ttyUSB0"  # adapte selon ton port

print("Connecting to Arduino Mega / Auriga...")
board = ArduinoMega(PORT)

print("\n=== BOARD INFORMATION ===")
print("Port:", PORT)
print("Digital pins count:", len(board.digital))
print("Analog pins count:", len(board.analog))

# Lister toutes les pins digitales disponibles
print("\n=== DIGITAL PINS TEST ===")
usable_digital = []

for i in range(len(board.digital)):
    try:
        pin = board.get_pin(f'd:{i}:o')  # o = output
        pin.write(0)  # test initialisation
        usable_digital.append(i)
        print(f"Digital pin {i}: usable")
    except Exception:
        print(f"Digital pin {i}: unavailable")

# Lister toutes les pins analogiques disponibles
print("\n=== ANALOG PINS TEST ===")
usable_analog = []

for i in range(len(board.analog)):
    try:
        pin = board.get_pin(f'a:{i}:i')  # i = input
        pin.read()  # test lecture
        usable_analog.append(f"A{i}")
        print(f"Analog pin A{i}: usable")
    except Exception:
        print(f"Analog pin A{i}: unavailable")

# Test rapide : clignoter toutes les pins digitales trouvées
print("\n=== BLINK TEST ON DIGITAL PINS ===")
for p in usable_digital:
    try:
        pin = board.get_pin(f'd:{p}:o')
        print(f"Blinking pin {p}...")
        pin.write(1)
        time.sleep(0.2)
        pin.write(0)
    except Exception:
        print(f"Pin {p} not usable for blinking")

print("\n=== SUMMARY ===")
print("Usable digital pins:", usable_digital)
print("Usable analog pins:", usable_analog)

print("\nDone.")

