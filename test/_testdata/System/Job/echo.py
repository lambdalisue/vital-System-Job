import sys
import time

if sys.argv[1] == 'stdout':
    fo = sys.stdout
else:
    fo = sys.stderr

if sys.argv[2] == 'cr':
    newline = "\r"
elif sys.argv[2] == 'lf':
    newline = "\n"
else:
    newline = "\r\n"

fo.write('Hello')
fo.flush()
time.sleep(0.1)
fo.write(' World')
fo.flush()
time.sleep(0.1)
fo.write(newline)
fo.flush()
time.sleep(0.1)
fo.write('Hello')
fo.flush()
time.sleep(0.1)
fo.write(' World')
fo.flush()
time.sleep(0.1)
fo.write(newline)
fo.flush()
time.sleep(0.1)
fo.write('This is not line')
