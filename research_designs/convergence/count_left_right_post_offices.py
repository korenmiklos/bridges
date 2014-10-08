import json
import csv
from quadtree import QuadTree, Feature, point_in_rectangle
from shapely.geometry import shape, Polygon, MultiPoint
from shapely import speedups
import sys
from project_geojson import ProjectedFeature

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

keep = ['name', 'start', 'river_mile', 'lat', 'lon']
writer = csv.DictWriter(sys.stdout, 
	fieldnames=keep+
	['left_5km_%s' % decade for decade in decades]+
	['right_5km_%s' % decade for decade in decades]+
	['left_10km_%s' % decade for decade in decades]+
	['right_10km_%s' % decade for decade in decades]
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

for record in records:
	# save lat lon for future use
	record['lon'] = record['geometry'].x
	record['lat'] = record['geometry'].y

	bridge_disc_5 = disc(record['geometry'], radius=5.0) 
	bridge_disc_10 = disc(record['geometry'], radius=10.0) 

	left_side_5 = shape(left_bank).buffer(0).intersection(bridge_disc_5)
	right_side_5 = shape(right_bank).buffer(0).intersection(bridge_disc_5)
	left_side_10 = shape(left_bank).buffer(0).intersection(bridge_disc_10)
	right_side_10 = shape(right_bank).buffer(0).intersection(bridge_disc_10)

	for decade in decades:
		record['left_5km_%s' % decade] = sum([1 for po in post_offices.get_overlapping_points(Feature(geometry=left_side_5)) if po['properties']['from']<=decade])
		record['right_5km_%s' % decade] = sum([1 for po in post_offices.get_overlapping_points(Feature(geometry=right_side_5)) if po['properties']['from']<=decade])
		record['left_10km_%s' % decade] = sum([1 for po in post_offices.get_overlapping_points(Feature(geometry=left_side_10)) if po['properties']['from']<=decade])
		record['right_10km_%s' % decade] = sum([1 for po in post_offices.get_overlapping_points(Feature(geometry=right_side_10)) if po['properties']['from']<=decade])
	del record['geometry']
	writer.writerow(record)

