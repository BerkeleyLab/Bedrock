#!/usr/bin/env python3
"""
FEED acquisition device logic substitution generator

[
    {
        # required
        "reset":{"name":"reg_reset","bit": 0}
        ,"status":{"name":"reg_status","bit": 1	}
        ,"trg:prefix:"
        # optional
        ,"readback":[
            "scalar1":{"name":"reg_name", "prefix":"SCLR1:"}
            ,"wf1":{
                "name":"reg_name1"
                ,"max_size":8196,
                ,"mask":"mask_reg"
                ,"prefix":"WF1:"
                ,"signals":[
                    {"prefix":"WF1:CH1:"}
                ]
            }
        ]
    }
]
"""

from __future__ import print_function

import json, re, itertools
from collections import OrderedDict

try:
    from itertools import izip as zip
except ImportError:
    pass

try:
    from cStringIO import StringIO
except ImportError:
    from io import StringIO

def strip_comments(inp):
    return re.sub(r'#.*$', '', inp, flags=re.MULTILINE)

def getargs():
    from argparse import ArgumentParser
    P = ArgumentParser()
    P.add_argument('json', help='json config file')
    P.add_argument('output', help='output .substitution file')
    return P.parse_args()

def batchby(it, cnt):
    grp = []
    for item in it:
        grp.append(item)
        if len(grp)==cnt:
            yield grp
            grp = []
    if len(grp):
        yield grp

class Main(object):
    def __init__(self, args):
        with open(args.json, 'r') as F:
            raw = F.read()

        cooked = strip_comments(raw)

        try:
            conf = json.loads(cooked)
        except:
            print("Error parsing JSON")
            print("======")
            print(cooked)
            raise

        # {"file.template": [('macro', 'value'), ...], ...}
        self.out = OrderedDict([
            ('feed_logic_trigger.template', []),
            ('feed_logic_read.template', []),
            ('feed_logic_array_mask.template', []),
            ('feed_logic_fanout.template', []),
            ('feed_logic_signal.template', []),
            ('feed_logic_pair.template', []),
            ('feed_logic_stats.template', []),
            ('feed_logic_decim.template', []),
        ])

        for gconf in conf:
            #out.write('### Start Signal Group: %s\n#\n'%gname)
            #for line in json.dumps(gconf, indent='  ').splitlines():
            #    out.write('%s\n'%line)

            gname = gconf.get('prefix')
            if not gname:
                continue

            self.signal_group(gname, gconf)

            #out.write('\n### End Signal Group: %s\n'%name)

        fd = StringIO()
        fd.write("# Generated from:\n")
        for line in raw.splitlines():
            fd.write('# %s\n'%line)
        fd.write("\n")

        for fname, lines in self.out.items():
            if not lines:
                fd.write("\n# no %s\n"%fname)
                continue

            fd.write("""
file "%s"
{
"""%fname)

            lines.reverse()
            for ent in lines:
                fd.write('{' + ', '.join(['%s="%s"'%(k,v) for k, v in ent.items()]) + '}\n')

            fd.write("}\n")

        with open(args.output, 'w') as F:
            F.write(fd.getvalue())

    def signal_group(self, gname, gconf):
        decim = None
        if 'decim' in gconf:
            ent = OrderedDict([
                ('BASE', '$(PREF)'+(gconf['decim'].get('prefix') or gname)),
                ('REG', gconf['decim']['name']),
            ])
            self.out['feed_logic_decim.template'].append(ent)
            decim = ent['BASE']+'DECIM_RBV CP MSI'

        # we append template blocks in reverse order to simplify accounting of next record.
        # start with the last link in the chain, which then re-arms
        nextrec = '$(PREF)%sREARM'%gname

        stats = []

        # de-mux of signals from array registers.
        # these will be synchronously processed through a set of fanouts
        fanout2 = []
        for rconf in gconf.get('readback', []):
            rname = rconf.get('prefix') or rconf['name']
            signals = rconf.get('signals', [])
            mask = hex((1<<len(signals))-1)

            if mask and 'mask' in rconf:
                # this register has a mask
                ent = OrderedDict([
                    ('BASE', '$(PREF)%s'%rname),
                    ('REG', rconf['mask'])
                ])
                mask = ent['BASE']+'MASK CP MSI'
                self.out['feed_logic_array_mask.template'].append(ent)

            for idx, signal in enumerate(signals):
                ent = OrderedDict([
                    ('BASE', '$(PREF)%s'%signal['prefix']),
                    ('REG', rconf['name']),
                    ('SIZE', str(rconf.get('max_size', 8196))),
                    ('IDX', str(idx)),
                    ('MASK', mask),
                    ('TBREF', '$(PREF)%sPERIOD CP MSI'%gname),
                ])
                if decim:
                    ent['TBDIV'] = decim
                if 'scale' in signal:
                    ent['SCALE'] = signal['scale']
                ent['FLNK'] = ent['BASE']+'SE_'
                stats.append((ent['BASE'], ent['BASE']+"WF", ent['BASE']+"TWF", ent['SIZE'], None))

                fanout2.append(ent['BASE']+'E_')
                self.out['feed_logic_signal.template'].append(ent)

            for iq in rconf.get('iq') or []:
                ent = OrderedDict([
                    ('BASE', '$(PREF)%s'%iq['prefix']),
                    ('IBASE', '$(PREF)%s'%iq['iprefix']),
                    ('QBASE', '$(PREF)%s'%iq['qprefix']),
                    ('SIZE', str(rconf.get('max_size', 8196))),
                ])
                fanout2.append(ent['BASE']+'E_')
                ent['FLNK'] = ent['BASE']+'ASE_'
                self.out['feed_logic_pair.template'].append(ent)
                stats.append((ent['BASE']+'A', ent['BASE']+'AWF', ent['BASE']+'TWF', ent['SIZE'], ent['BASE']+'PSE_'))
                stats.append((ent['BASE']+'P', ent['BASE']+'PWF', ent['BASE']+'TWF', ent['SIZE'], None))


        for statprefix, sig, tsig, size, flnk in stats:
            ent = OrderedDict([
                ('BASE', statprefix),
                ('SIGNAL', sig),
                ('TIME', tsig),
                ('TRIGGER', '$(PREF)'+gname),
                ('SIZE', size),
                # ('PHASWRAP', '0'),
            ])
            if flnk:
                ent['FLNK'] = flnk
            self.out['feed_logic_stats.template'].append(ent)

        nextfo = itertools.count(1)
        fanout2 = list(batchby(fanout2, 6))
        fanout2.reverse()

        # emit fanouts to process all signals
        for records, idx in zip(fanout2, nextfo):
            ent = OrderedDict([
                ('NAME', '$(PREF)%sFO%d_'%(gname, idx)),
            ])

            for n, record in enumerate(records, 1):
                ent['LNK%d'%n] = record
            ent['FLNK'] = nextrec
            nextrec = ent['NAME']

            self.out['feed_logic_fanout.template'].append(ent)

        # read back registers
        for rconf in gconf.get('readback', []):
            rname = rconf.get('prefix') or rconf['name']
            ent = OrderedDict([
                ('BASE', '$(PREF)%s'%rname),
                ('REG', rconf['name']),
                ('FLNK', nextrec),
            ])
            nextrec = ent['BASE']+'E_'
            self.out['feed_logic_read.template'].append(ent)


        # finally the beginning
        self.out['feed_logic_trigger.template'].append(OrderedDict([
            ('BASE', '$(PREF)'+gname),
            ('ARM_REG', gconf['reset']['name']),
            ('ARM_MASK', hex(1<<gconf['reset']['bit'])),
            ('RDY_REG', gconf['status']['name']),
            ('RDY_MASK', hex(1<<gconf['status']['bit'])),
            ('PERIOD', gconf.get('tsamp', 1.0)),
            ('NEXT', nextrec),
        ]))


if __name__=='__main__':
    args = getargs()
    Main(args)
