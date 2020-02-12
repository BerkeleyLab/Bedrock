#!/usr/bin/env python

import os
import sys
import logging
import json

datadir = os.path.dirname(__file__)


def getargs():
    from argparse import ArgumentParser
    P = ArgumentParser('%s -m leep.eng' % sys.executable,
                       description='Engineering screen (cs-studio/display builder) generator')
    P.add_argument('-d', '--debug', action='store_const',
                   const=logging.DEBUG, default=logging.INFO)
    P.add_argument('-q', '--quiet', action='store_const',
                   const=logging.WARN, dest='debug')
    P.add_argument('--prefix', default='$(REG)',
                   help="Record name prefix.  default: '$(REG)'")
    P.add_argument('output', help='output .bob file')
    P.add_argument('json', help='input json register map')
    return P.parse_args()


def main(args):
    import xml.etree.ElementTree as ET
    T = ET.parse(os.path.join(datadir, 'base.bob')).getroot()

    with open(args.json, 'r') as F:
        blob = json.load(F)

    # sort by register name for stability
    blob = list(blob.items())
    blob.sort(key=lambda i: i[0])

    nextrow = 0
    for name, info in blob:
        if info.get('addr_width', 0) != 0:
            continue  # don't emit for waveforms

        if info.get('data_width', 0) == 1:
            fname = 'BinaryUpdate.bob'
        elif info.get('access', '').find('w') != -1:
            fname = 'TextEntry.bob'
        else:
            fname = 'TextUpdate.bob'
        W = ET.parse(os.path.join(datadir, fname)).getroot()

        read_pv_name = "%sreg_%s_RBV" % (args.prefix, name)
        set_pv_name = "%sreg_%s" % (args.prefix, name)

        NY = 0
        for W in list(W.findall('widget')):
            Y = W.find('y') or ET.SubElement(W, 'y')
            Y.text = str(int(Y.text or '0')+nextrow)

            NY = max(NY, int(W.find('height').text))

            if W.find('name').text in ['Label', 'Readback', 'Setting', 'Slider']:
                txt = W.find('text')
                if txt is not None:
                    txt.text = name

            pv_name = W.find('pv_name')
            if pv_name is None:
                pass
            elif pv_name.text == 'Readback':
                pv_name.text = read_pv_name
            elif pv_name.text == 'Setting':
                pv_name.text = set_pv_name

            T.append(W)

        nextrow += NY

    with open(args.output, 'wb') as F:
        F.write(b'<?xml version="1.0" encoding="UTF-8"?>\n')
        F.write(ET.tostring(T))


if __name__ == '__main__':
    args = getargs()
    logging.basicConfig(level=args.debug)
    main(args)
