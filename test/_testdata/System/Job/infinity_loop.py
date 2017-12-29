import sys
import time

# Do not add \r even in Windows
if sys.platform.startswith('win'):
    import os
    import msvcrt
    msvcrt.setmode(sys.stdout.fileno(), os.O_BINARY)
    msvcrt.setmode(sys.stderr.fileno(), os.O_BINARY)

while True:
    print('Stop this iteration by hitting Ctrl-C')
    time.sleep(1)
