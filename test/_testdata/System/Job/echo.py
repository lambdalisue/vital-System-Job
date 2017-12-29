import sys
import time

# To prevent 'universal newline' in Windows.
# Open a new stdout/stderr with newline='\n'
if sys.argv[1] == 'stdout':
    fo = open(
        sys.__stdout__.fileno(),
        sys.__stdout__.mode,
        buffering=1,
        encoding=sys.__stdout__.encoding,
        errors=sys.__stdout__.errors,
        newline='\n',
        closefd=False,
    )
else:
    fo = open(
        sys.__stderr__.fileno(),
        sys.__stderr__.mode,
        buffering=1,
        encoding=sys.__stderr__.encoding,
        errors=sys.__stderr__.errors,
        newline='\n',
        closefd=False,
    )

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
