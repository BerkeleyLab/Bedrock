#!/bin/env python

from socket import *
import string, time, sys
from datetime import datetime, timedelta

class QSFP_INFO:
        IDENTIFIER = {
                1 : 'GBIC',
                2 : 'Module / connector soldered to motherboard',
                3 : 'SFP or SFP+',
                4 : '300 pin XBI',
                5 : 'XENPAK',
                6 : 'XFP',
                7 : 'XFF',
                8 : 'XFP-E',
                9 : 'XPAK',
                10 : 'X2',
                11 : 'DWDM-SFP',
                12 : 'QSFP',
                13 : 'QSFP+',
                14 : 'CXP'
                }

        STATUS = {
                0 : 'PAGED UPPER MEMORY, INTERRUPT ACTIVE, MEMORY DATA READY',
                1 : 'PAGED UPPER MEMORY, INTERRUPT ACTIVE, MEMORY DATA NOT READY',
                2 : 'PAGED UPPER MEMORY, INTERRUPT INACTIVE, MEMORY DATA READY',
                3 : 'PAGED UPPER MEMORY, INTERRUPT INACTIVE, MEMORY DATA NOT READY',
                4 : 'NO UPPER MEMORY, INTERRUPT ACTIVE, MEMORY DATA READY',
                5 : 'NO UPPER MEMORY, INTERRUPT ACTIVE, MEMORY DATA NOT READY',
                6 : 'NO UPPER MEMORY, INTERRUPT INACTIVE, MEMORY DATA READY',
                7 : 'NO UPPER MEMORY, INTERRUPT INACTIVE, MEMORY DATA NOT READY',
                }
