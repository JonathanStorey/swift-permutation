import json, sys
d = json.load(open(sys.argv[1]))
def walk(x):
    if isinstance(x, dict):
        content = x.get('inlineContent', [])
        if x.get('type') == 'paragraph' and any(isinstance(i, dict) and i.get('text', '').startswith('Probe') for i in content):
            print(content)
        for v in x.values():
            walk(v)
    elif isinstance(x, list):
        for v in x:
            walk(v)
walk(d)
