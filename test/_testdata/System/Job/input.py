import sys

# Do not add \r even in Windows
if sys.platform.startswith('win'):
    import os
    import msvcrt
    msvcrt.setmode(sys.stdout.fileno(), os.O_BINARY)
    msvcrt.setmode(sys.stderr.fileno(), os.O_BINARY)

if sys.version_info >= (3, 0):
    name = input('Please input your name: ')
else:
    name = raw_input('Please input your name: ')
print('Hello %s' % name)
