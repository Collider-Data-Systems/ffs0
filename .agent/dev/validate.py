import json
import jsonschema
from pathlib import Path

def validate_json(instance_path, schema_path):
    with open(instance_path, 'r', encoding='utf-8') as f:
        instance = json.load(f)
    with open(schema_path, 'r', encoding='utf-8') as f:
        schema = json.load(f)
    try:
        jsonschema.validate(instance=instance, schema=schema)
        print(f"PASS: {instance_path} validates against {schema_path}")
        return True
    except Exception as e:
        print(f"FAIL: {instance_path} validation error: {e.message if hasattr(e, 'message') else e}")
        return False

print("Validating ontology.json...")
validate_json('superset/ontology.json', 'superset/schemas/ontology.schema.json')

print("\nValidating instances/*.json...")
for p in Path('instances').glob('*.json'):
    validate_json(str(p.as_posix()), 'superset/schemas/instance.schema.json')

print("\nTesting industry.schema.json with missing 'source' payload...")
with open('superset/schemas/industry.schema.json', 'r', encoding='utf-8') as f:
    ind_schema = json.load(f)

test_payload_missing_source = {
    "domain": "test",
    "ontology_targets": ["OBJ01"],
    "entries": [{"id": "1", "name": "Test"}]
}

try:
    jsonschema.validate(instance=test_payload_missing_source, schema=ind_schema)
    print("FAIL: industry payload missing 'source' WAS NOT rejected")
except jsonschema.exceptions.ValidationError as e:
    print(f"PASS: industry payload missing 'source' WAS rejected. Caught error: '{e.message}'")
