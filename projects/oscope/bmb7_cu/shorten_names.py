import argparse
import json

def shorten_names(regmap, iteration=0):
    word_to_remove = ''
    names = regmap.keys()
    longest = max(sorted(names), key=len)
    if len(longest) <= 40: return regmap
    ss = longest.split('_')  # ss: substrings
    # print(len(regmap), longest, len(longest))
    position = 0
    rebuilt_s = ''
    for s in ss:
        rebuilt_s += s + '_'
        if s.isdigit() or s in ['cavity', 'mode', 'shell']: continue
        F = lambda x: x.replace(s +'_', '', 1) if x.startswith(rebuilt_s) else x
        rebuilt_set = set(map(F, names))
        if len(rebuilt_set) == len(names):
            word_to_remove = s
            break
        position += len(s) + 1
    if word_to_remove:
        # print(iteration, word_to_remove)
        S = {}
        for n in names:
            new = n.replace(word_to_remove + '_', '', 1) if n.startswith(rebuilt_s) else n
            S[new] = regmap[n]
        return shorten_names(S, iteration + 1)
    else: return regmap

def main():
    parser = argparse.ArgumentParser(description='Merge json files and complain on key collision')
    parser.add_argument('-i', '--input_regmap_json', default='prc_regmap.json',
                        help='A regmap json file whose keys are to be shortened')
    parser.add_argument('-o', '--shortened_regmap_json', default='_output.json', type=str,
                        help='Merged with json file')
    args = parser.parse_args()
    with open(args.input_regmap_json, 'r') as in_file:
        regmap = shorten_names(json.load(in_file))
        with open(args.shortened_regmap_json, 'w') as out_file:
            json.dump(regmap, out_file, sort_keys=True, indent=4, separators=(',', ': '))

if __name__ == "__main__":
    main()
