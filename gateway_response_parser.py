import json

with open("gateway_response.json") as f:
    resp = json.load(f)

if resp["status"] == "success":
    exit(0)
else:
    exit(1)