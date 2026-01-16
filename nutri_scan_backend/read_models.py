import json

with open("models.json", "r") as f:
    data = json.load(f)
    print("--- VISION/3.2 MODELS ---")
    for m in data['data']:
        if 'vision' in m['id'] or '3.2' in m['id']:
            print(m['id'])
