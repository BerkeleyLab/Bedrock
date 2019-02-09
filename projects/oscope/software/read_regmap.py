import re


def get_map(f='regmap_gen_vmod1.json'):
    if f.endswith('.json'):
        import json
        with open(f) as json_map:
            return json.load(json_map)
    regmap = {}
    # Currently below only supports a line of length 2,
    # with format '<reg_name> <reg_addr>'
    for l in open(f, 'r'):
        l = l.strip()
        l = l.split()
        if len(l) != 2:
            print(("Something wrong with the line width: ", l))
            exit()
        else:
            try:
                regmap[l[0]] = int(l[1])
            except ValueError:
                print(('Unexpected literal: %s in file: %s' % l[1], f))
                exit()
    return regmap


H = [[
    "llrf", "shell", "tgen", "cavity", "station", "station_cav4_elec", "rc_dsp"
], ["mode", "freq", "outer_prod", "dot"]]


def add_name(regmap, name):
    a = {"name": name}
    a.update(regmap[name])
    return a


def get_reg_info(regmap, hierarchy, name):
    """
    regmap: is a python dictionary of json regmap generated from ./newad.py
    name: is potentially an unique identifier of a register name inside the
          regmap.
    This method tries to identify the register with the name and return it's
    info hierarchy is something that can be used to help the user.
    eg: get_reg_info({...}, [0,1], coarse_freq), looks for the name coarse_freq
        in cavity_0_cav4_elec_mode_1. Since verilog name convention is far from
        perfect this method tries to ease the pain on the python user, to grab
        the register info
    TODO: This function can be abstracted and the core below must be made
    recursive
    """
    reg_names = list(regmap.keys())
    # print(sorted(reg_names), hierarchy, name)
    # print('Looking for register \'%s\' in: ' %
    # name, sorted(reg_names), hierarchy)
    if type(name) is list:
        for n in name:
            reg_names = [x for x in reg_names if n in x]
    else:
        if name in regmap:
            reg_names = [name]
        else:
            reg_names = [x for x in reg_names if name in x]
    if len(reg_names) == 0:
        return None
    elif len(reg_names) == 1:
        return add_name(regmap, reg_names[0])
    if type(hierarchy) is list and len(hierarchy) > 0:
        answers = []
        for h in H[0]:
            n = hierarchy[0]
            p = '_' if type(n) is int else ''
            reg_names_1 = [x for x in reg_names if (h + p + str(n)) in x]
            if len(reg_names_1) == 1:
                answers.append(add_name(regmap, reg_names_1[0]))
            if len(hierarchy) > 1:
                n = hierarchy[1]
                p = '_' if type(n) is int else ''
                for h in H[1]:
                    reg_names_2 = [x for x in reg_names_1 if (h + p + str(n)) in x]
                    if len(reg_names_2) == 1:
                        answers.append(add_name(regmap, reg_names_2[0]))
                    elif len(reg_names_2) > 1:
                        raise Exception(
                            'Too many register names match %s\n%s' %
                            (name, str(reg_names_2)))
        if len(answers) == 1:
            return answers[0]
        elif len(answers) > 1:
            print(answers)
            raise Exception('Too many register names match %s\n%s' %
                            (str(answers)))
    elif len(reg_names) > 1:
        raise Exception('Too many register names match %s\n%s' %
                        (name, str(reg_names)))

    print(('Register not found : ' + str(name)))
    return None


def get_write_address(name, regmap, hierarchy=[]):
    if type(name) is int:
        return name
    else:
        try:
            return int(name, 0)
        except:
            pass
        offset = 0
        if name.endswith(']'):
            x = re.search('^(\w+)\s*\[(\d+)\]', name)
            if x:
                name, offset = x.group(1), int(x.group(2))
        r = get_reg_info(regmap, hierarchy, name)
        try:
            return r['base_addr'] + offset
        except:
            print(("get_write_address failed on %s" % name))


def get_read_address(name, regmap, hierarchy=[]):
    return get_write_address(name, regmap, hierarchy)


if __name__ == '__main__':
    # test case
    blah = {'bl': 'ah'}
    print((get_reg_info({"station_cav4_elec_modulo": blah}, [], 'old')))
    print((get_reg_info({"station_cav4_elec_modulo": blah}, [], 'ulo')))
    print((get_reg_info({"station_cav4_elec_modulo": blah}, [], 'modulo')))
    print((get_reg_info({
        "station_cav4_elec_modulo": blah,
        "station_0_cav4_elec_modulo": blah
    }, [], 'o')))
