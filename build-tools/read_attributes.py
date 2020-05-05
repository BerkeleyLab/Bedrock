from v2j import v2j


def read_attributes(yosys_json):
    # TODO: Need to implement top-level
    '''
    yosys_json: yosys command 'write_json' output
    '''
    if len(yosys_json['modules'].keys()) != 1:
        print('WARNING: Newad expects 1 module per file with the same name,'
              ' this voids warranty')
    this_mod = list(yosys_json['modules'].keys())[0]

    module = yosys_json['modules'][this_mod]
    mod_name = list(yosys_json['modules'].keys())[0]
    assert(this_mod == mod_name)
    # print(json.dumps(module, indent=4))
    # print('external nets')
    for mod_name in yosys_json['modules']:
        mod_info = {'external_nets': {}, 'automatic_cells': {}}
        for port, port_info in module['ports'].items():
            net_info = module['netnames'][port]
            if 'external' in net_info['attributes']:
                assert(port not in mod_info['automatic_cells'])
                # print(port, net_info, net_info['attributes'], port_info)
                mod_info['external_nets'][port] = net_info, port_info
        # print('lb_automatic cells')
        for cell, cell_info in module['cells'].items():
            if 'lb_automatic' in cell_info['attributes']:
                assert(cell not in mod_info['automatic_cells'])
                mod_info['automatic_cells'][cell] = cell_info
                # print(cell, cell_info)
    return mod_info


if __name__ == "__main__":
    import sys
    assert(len(sys.argv) == 2)
    read_attributes(v2j(sys.argv[1]))
