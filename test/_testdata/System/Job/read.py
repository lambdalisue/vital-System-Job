import sys

# Do not add \r even in Windows
if sys.platform.startswith('win'):
    import os
    import msvcrt
    msvcrt.setmode(sys.stdout.fileno(), os.O_BINARY)
    msvcrt.setmode(sys.stderr.fileno(), os.O_BINARY)

data = ""
line = sys.stdin.readline()
while line != ".\n":
    data += line
    line = sys.stdin.readline()

print('read:')
print(data.replace('\0', '<NUL>'))
