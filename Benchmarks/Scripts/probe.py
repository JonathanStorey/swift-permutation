import json, sys
from collections import Counter
d = json.load(open(sys.argv[1]))
used = Counter()
def walk(x):
    if isinstance(x, dict):
        if x.get('type') == 'reference' and 'identifier' in x:
            used[x['identifier']] += 1
        for k, v in x.items():
            if k != 'references':
                walk(v)
    elif isinstance(x, list):
        for v in x:
            walk(v)
walk(d)
for identifier, count in sorted(used.items()):
    if identifier.endswith('/Permutation') or '/Permutation/Permutation' in identifier and identifier.count('/') <= 6:
        print(count, identifier)
