import argparse
import json
import copy
import re


def _inc_append(s):
    """Append _N to string 's' (where 'N' is an integer) or increment 'N'
    if it already exists."""
    _match = re.match(r"(\w+)_([0-9]+)$", s)
    if _match:
        pre, post = _match.groups()
        post_int = int(post)
        return pre + '_' + str(post_int + 1)
    return s + '_0'


def merge_with_quit_on_collision(*args, resolve=None):
    '''
    The idea is not to write performant code, but correct code (Which I couldn't find)
    '''
    args, = args
    final = {}
    conflicts = []
    for f in args:
        with open(f, 'r') as json_file:
            json_dict = json.load(json_file)
            if type(json_dict) is not dict:
                exit('file {} isnt a json dictionary'.format(f))
            for k in json_dict:
                if k in final and resolve is None:
                    conflicts.append('key {} in file {} already exists in a previously merged file'.format(k, f))
                else:
                    entry = json_dict[k]
                    if k in final:
                        if resolve == "suffix":
                            k = _inc_append(k)
                        elif resolve == "priority":
                            continue
                    # Allow (string) hex numbers for base_addr in input,
                    # but convert them to numeric here; always emit decimal.
                    if "base_addr" in entry:
                        aa = entry["base_addr"]
                        if type(aa) is str:
                            entry["base_addr"] = int(aa, 0)
                    final[k] = entry
    if len(conflicts) > 0:
        exit('\n'.join(conflicts))
    # caller needs to figure out the consequences of non-blank conflict message
    return final, '\n'.join(conflicts)


def expand_arrays(json_dict, aw_threshold=2, verbose=False):
    ''' Expand register array to individual per-element registers for arrays of
    address width <= aw_threshold
    '''
    names = [k for k in json_dict if 'addr_width' in json_dict[k] and 0 < json_dict[k]['addr_width'] <= aw_threshold]
    for name in names:
        k_expansion = {}
        if verbose:
            print(name)
            print(json_dict[name])
        for ix in range(2**json_dict[name]['addr_width']):
            element_name = name+'_{}'.format(ix)
            k_expansion.update({element_name: copy.deepcopy(json_dict[name])})
            k_expansion[element_name]['addr_width'] = 0
            k_expansion[element_name]['base_addr'] = json_dict[name]['base_addr'] + ix
            if verbose:
                print(element_name)
                print(json_dict[name]['base_addr'])
                print(ix)
                print(k_expansion[element_name])
        del json_dict[name]
        json_dict.update(k_expansion)


def split_digaree(json_dict, verbose=False):
    ''' Special-case to separate out quench-detection parameters from detuning
    '''
    k_expansion = {}
    names = [k for k in json_dict if 'piezo_sf_consts' in k]
    for name in names:
        if json_dict[name]['addr_width'] != 3:
            print("split_digaree is confused")
            continue
        element_name = name[:-15] + "quench_sf_consts"
        if verbose:
            print(name, element_name)
        k_expansion.update({element_name: copy.deepcopy(json_dict[name])})
        k_expansion[element_name]['base_addr'] = json_dict[name]['base_addr'] + 4
        k_expansion[element_name]['addr_width'] = 2
        json_dict[name]['addr_width'] = 2
    json_dict.update(k_expansion)


def main():
    parser = argparse.ArgumentParser(description='Merge json files and complain on key collision')
    parser.add_argument('-i', '--input_json_file_list', nargs='+',
                        help='A list of json files to be merged')
    parser.add_argument('-o', '--output_json_file', default='.', type=str,
                        help='Resulting merged json file')
    parser.add_argument('-r', '--resolve', default=None,
                        help="Auto-resolve conflicts (\"none\", \"suffix\", \"priority\")")
    args = parser.parse_args()
    resolve = args.resolve
    if resolve is not None:
        resolve = resolve.lower().strip()
        if resolve == "none":
            resolve = None
    merged_dict, conflicts = merge_with_quit_on_collision(args.input_json_file_list, resolve=resolve)
    print(conflicts)
    if conflicts != "" and resolve is None:
        print("merge_json aborting due to conflicts")
        exit(1)
    # Probably should make the next two processing steps controllable with parser arguments
    expand_arrays(merged_dict)
    split_digaree(merged_dict)
    #
    with open(args.output_json_file, 'w') as out_file:
        json.dump(merged_dict,
                  out_file, sort_keys=True, indent=4, separators=(',', ': '))


def test_inc_append(argv):
    ss = argv[1]
    sss = _inc_append(ss)
    print(sss)


if __name__ == "__main__":
    # import sys
    # test_inc_append(sys.argv)
    main()
