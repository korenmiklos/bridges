import json
import csv
from quadtree import QuadTree, Feature, point_in_rectangle
from shapely.geometry import shape, Polygon, MultiPoint
from shapely import speedups
import sys
from project_geojson import ProjectedFeature
from copy import deepcopy

def disc(geometry, radius=5.0):
	return ProjectedFeature(ProjectedFeature(geometry, 'wgs84').lcc.buffer(radius*1000.0), 'lcc').wgs84

def get_every_10k_points(line_in_meters):
	length = line_in_meters.length
	covered = 0
	points = []
	while covered<length:
		points.append(dict(river_mile=int(covered/1600.0), geometry=line_in_meters.interpolate(covered)))
		covered += 10000.0
	return points

def wgs84_distance(point1, point2):
	'''
	Distance between two WGS84 points in kilometers.
	'''
	return ProjectedFeature(point1, 'wgs84').lcc.distance(ProjectedFeature(point2, 'wgs84').lcc)/1000.0

speedups.enable()

river = sys.argv[1]
# we will not use any of the later post offices, so stop in 1900
decades = [str(year) for year in range(1790,1900,1)]

geojson = json.load(open("../../data/us-postal-history/consistent/postoffices.geojson"))
bridges = json.load(open("../../data/rivers/%s/bridges.geojson" % river))['features']
bridge_collection = MultiPoint([shape(bridge['geometry']) for bridge in bridges])
river_line_meters = ProjectedFeature(json.load(open("../../data/rivers/%s/river.geojson" % river))['features'][0]['geometry'], 'wgs84').lcc
potential_control_regions = [dict(river_mile=point['river_mile'], 
	geometry=ProjectedFeature(point['geometry'],'lcc')) for point in get_every_10k_points(river_line_meters)]

# control regions have no bridge within 10km
control_regions_10 = [region for region in potential_control_regions if not disc(region['geometry'].geometry, radius=10.0).intersects(bridge_collection)]
# we also want to look at the 5km center of these regions

left_bank = json.load(open("../../data/rivers/%s/left_bank.geojson" % river))['geometry']
right_bank = json.load(open("../../data/rivers/%s/right_bank.geojson" % river))['geometry']

keep = ['id', 'name', 'start', 'river_mile', 'lat', 'lon']
writer = csv.DictWriter(sys.stdout, 
	fieldnames=keep+
	['distance', 'po_from', 'po_to', 'side']
	)
writer.writeheader()

post_offices = QuadTree(geojson['features'])
records = []

for bridge in bridges:
	record = {}
	record['geometry'] = shape(bridge['geometry'])
	for field in ['name', 'start', 'river_mile']:
		record[field] = bridge['properties'][field]
	records.append(record)

for region in control_regions_10:
	record = {}
	record = dict(name='Control region with no bridge', river_mile=region['river_mile'])
	record['geometry'] = region['geometry'].geometry
	records.append(record)

i = 0
for record in records:
	i += 1
	record['id'] = i

	# save lat lon for future use
	record['lon'] = record['geometry'].x
	record['lat'] = record['geometry'].y

	bridge = shape(record['geometry'])

	bridge_disc = disc(record['geometry'], radius=20.0) 
	left_side = shape(left_bank).buffer(0).intersection(bridge_disc)
	right_side = shape(right_bank).buffer(0).intersection(bridge_disc)

	for po in post_offices.get_overlapping_points(Feature(geometry=left_side)):
		row = deepcopy(record)
		# calculate distance to bridge
		row['distance'] = wgs84_distance(shape(po['geometry']), bridge)
		row['side'] = 'left'
		row['po_from'] = po['properties']['from']
		row['po_to'] = po['properties']['to']

		del row['geometry']
		writer.writerow(row)
	for po in post_offices.get_overlapping_points(Feature(geometry=right_side)):
		row = deepcopy(record)
		# calculate distance to bridge
		row['distance'] = wgs84_distance(shape(po['geometry']), bridge)
		row['side'] = 'right'
		row['po_from'] = po['properties']['from']
		row['po_to'] = po['properties']['to']

		del row['geometry']
		writer.writerow(row)

