#!/usr/bin/env python3
import sys
import time

# To prevent 'universal newline' in Windows.
# Open a new stdout/stderr with newline='\n'
if sys.argv[1] == 'stdout':
    fo = sys.stdout.buffer
else:
    fo = sys.stderr.buffer

if sys.argv[2] == 'cr':
    newline = b"\r"
elif sys.argv[2] == 'lf':
    newline = b"\n"
else:
    newline = b"\r\n"

fo.write(b'Hello')
fo.flush()
time.sleep(0.1)
fo.write(b' World')
fo.flush()
time.sleep(0.1)
fo.write(newline)
fo.flush()
time.sleep(0.1)
fo.write(b'Hello')
fo.flush()
time.sleep(0.1)
fo.write(b' World')
fo.flush()
time.sleep(0.1)
fo.write(newline)
fo.flush()
time.sleep(0.1)
fo.write(b'This is not line')
