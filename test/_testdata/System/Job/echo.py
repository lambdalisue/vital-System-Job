#!/usr/bin/env python3
import sys
import time

if sys.argv[1] == 'stdout':
    fo = sys.stdout
else:
    fo = sys.stderr

fo.write('Hello')
fo.flush()
time.sleep(0.1)
fo.write(' World')
fo.flush()
time.sleep(0.1)
fo.write('\n')
fo.flush()
time.sleep(0.1)
fo.write('Hello')
fo.flush()
time.sleep(0.1)
fo.write(' World')
fo.flush()
time.sleep(0.1)
fo.write('\n')
fo.flush()
time.sleep(0.1)
fo.write('This is not line')
