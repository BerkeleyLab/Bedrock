import argparse
import json
import copy


def merge_with_quit_on_collision(*args):
    '''
    The idea is not to write performant code, but correct code (Which I couldn't find)
    '''
    args, = args
    final = {}
    for f in args:
        with open(f, 'r') as json_file:
            json_dict = json.load(json_file)
            if type(json_dict) is not dict:
                exit('file {} isnt a json dictionary'.fmt(f))
            for k in json_dict:
                if k in final:
                    exit('key {} in file {} already exists in a previously merged file'.fmt(k, f))
                else:
                    final[k] = json_dict[k]
    return final


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
                        help='Merged with json file')
    args = parser.parse_args()
    with open(args.output_json_file, 'w') as out_file:
        merged_dict = merge_with_quit_on_collision(args.input_json_file_list)
        expand_arrays(merged_dict)
        split_digaree(merged_dict)
        json.dump(merged_dict,
                  out_file, sort_keys=True, indent=4, separators=(',', ': '))


if __name__ == "__main__":
    main()
