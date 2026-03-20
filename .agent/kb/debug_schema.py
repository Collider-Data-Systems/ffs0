import json
import jsonschema

with open('superset/ontology.json', 'r', encoding='utf-8') as f:
    instance = json.load(f)
with open('superset/schemas/ontology.schema.json', 'r', encoding='utf-8') as f:
    schema = json.load(f)

v = jsonschema.Draft7Validator(schema)
for error in v.iter_errors(instance):
    print(f"Error at {list(error.path)}: {error.message}")

with open('instances/benchmarks.json', 'r', encoding='utf-8') as f:
    binstance = json.load(f)
with open('superset/schemas/instance.schema.json', 'r', encoding='utf-8') as f:
    bschema = json.load(f)

vb = jsonschema.Draft7Validator(bschema)
for error in vb.iter_errors(binstance):
    print(f"Benchmarks Error at {list(error.path)}: {error.message}")
