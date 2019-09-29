#!/usr/bin/env python

import sys


with open(sys.argv[1], "rb") as f:
    c = f.read(1)
    while ord(c) != 26:
        if ord(c) != 10:
            print("%c" % chr(ord(c)), end='')
        else:
            print("")            
        c = f.read(1)
    f.close
    





