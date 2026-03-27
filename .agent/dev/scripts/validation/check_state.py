import urllib.request, json

try:
    req = urllib.request.Request('http://127.0.0.1:8000/state', headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=5) as f:
        data = json.loads(f.read().decode('utf-8'))
    
    nodes = data.get('nodes', {})
    cats_keys = [k for k in nodes.keys() if k.startswith('urn:moos:cat:')]
    objs_keys = [k for k in nodes.keys() if k.startswith('urn:moos:obj:')]
    
    total = len(cats_keys) + len(objs_keys)
    
    s1_count = 0
    for k in cats_keys + objs_keys:
        if nodes[k].get('stratum') == 'S1':
            s1_count += 1
            
    print(f"cats: {len(cats_keys)}")
    print(f"objs: {len(objs_keys)}")
    print(f"total: {total}")
    print(f"all_s1: {s1_count == total and total > 0}")
    print(f"s1_count: {s1_count}")
except Exception as e:
    import traceback
    traceback.print_exc()
