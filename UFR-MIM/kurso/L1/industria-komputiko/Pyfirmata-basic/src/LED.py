from pyfirmata2 import Arduino
import time

board = Arduino('/dev/ttyUSB0')

LEDs = [board.get_pin(f'd:{LED_number}:o') for LED_number in (45,45)]

while True:
    for led in LEDs:
        led.write(1)
        time.sleep(1)
        led.write(0)
        time.sleep(1)
