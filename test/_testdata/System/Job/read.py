#!/usr/bin/env python3
import sys

data = ""
line = sys.stdin.readline()
while line != ".\n":
    data += line
    line = sys.stdin.readline()

print('read:')
print(data.replace('\0', '<NUL>'))
