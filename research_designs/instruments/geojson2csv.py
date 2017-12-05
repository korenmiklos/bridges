import csv, json, sys

items = [_['properties'] for _ in json.load(sys.stdin)['features']]

names = items[0].keys()
writer = csv.DictWriter(sys.stdout, fieldnames=names)
writer.writeheader()

for item in items:
	writer.writerow(item)
