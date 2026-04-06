#!/usr/bin/env python3

"""

assembler version 1.0

Usage:

python3 assembler.py program.s -o program.mem
python3 assembler.py program.s          # writes program.mem by default

"""

import sys, re, struct, argparse
from typing import Optional

"""

a function to sign extend the numbers,

say a number in 8 bit is 000 1010

after sign extending it to 16 bits, we get 0000 0000 0000 1010

"""

def signExtend(val: int, bits: int) -> int: 
    sign = 1 << (bits - 1)
    return (val & (sign - 1)) - (val & sign)