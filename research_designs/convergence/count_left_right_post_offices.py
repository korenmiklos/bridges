import json
import csv
from quadtree import QuadTree, Feature, point_in_rectangle
from shapely.geometry import shape, Polygon, MultiPoint
from shapely import speedups
import sys
from project_geojson import ProjectedFeature

def disc_10km(geometry):
	return ProjectedFeature(ProjectedFeature(geometry, 'wgs84').lcc.buffer(10000.0), 'lcc').wgs84

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
decades = [str(year) for year in range(1790,1960,10)]

geojson = json.load(open("../../data/us-postal-history/consistent/postoffices.geojson"))
bridges = json.load(open("../../data/rivers/%s/bridges.geojson" % river))['features']
bridge_collection = MultiPoint([shape(bridge['geometry']) for bridge in bridges])
river_line_meters = ProjectedFeature(json.load(open("../../data/rivers/%s/river.geojson" % river))['features'][0]['geometry'], 'wgs84').lcc
potential_control_regions = [dict(river_mile=point['river_mile'], 
	geometry=disc_10km(ProjectedFeature(point['geometry'],'lcc').wgs84)) for point in get_every_10k_points(river_line_meters)]

control_regions = [disc for disc in potential_control_regions if not disc['geometry'].intersects(bridge_collection)]

left_bank = json.load(open("../../data/rivers/%s/left_bank.geojson" % river))['geometry']
right_bank = json.load(open("../../data/rivers/%s/right_bank.geojson" % river))['geometry']

keep = ['name', 'start', 'river_mile']
writer = csv.DictWriter(sys.stdout, fieldnames=keep+['left_%s' % decade for decade in decades]+['right_%s' % decade for decade in decades])
writer.writeheader()

post_offices = QuadTree(geojson['features'])

for bridge in bridges:
	bridge_disc = disc_10km(bridge['geometry']) 
	left_side = shape(left_bank).buffer(0).intersection(bridge_disc)
	right_side = shape(right_bank).buffer(0).intersection(bridge_disc)
	bridge['properties']['post_office_count'] = {}
	for year in decades:
		po_count_left = sum([1 for po in post_offices.get_overlapping_points(Feature(geometry=left_side)) if po['properties']['from']<=year])
		po_count_right = sum([1 for po in post_offices.get_overlapping_points(Feature(geometry=right_side)) if po['properties']['from']<=year])
		bridge['properties']['post_office_count'][year] = (po_count_left, po_count_right)

	record = {}
	for field in keep:
		record[field] = bridge['properties'][field]
	for decade in decades:
		record['left_%s' % decade] = bridge['properties']['post_office_count'][decade][0]
		record['right_%s' % decade] = bridge['properties']['post_office_count'][decade][1]
	writer.writerow(record)

for region in control_regions:
	data = {}
	left_side = shape(left_bank).buffer(0).intersection(region['geometry'])
	right_side = shape(right_bank).buffer(0).intersection(region['geometry'])
	for year in decades:
		po_count_left = sum([1 for po in post_offices.get_overlapping_points(Feature(geometry=left_side)) if po['properties']['from']<=year])
		po_count_right = sum([1 for po in post_offices.get_overlapping_points(Feature(geometry=right_side)) if po['properties']['from']<=year])
		data[year] = (po_count_left, po_count_right)

	record = dict(name='Control region with no bridge', river_mile=region['river_mile'])
	for decade in decades:
		record['left_%s' % decade] = data[decade][0]
		record['right_%s' % decade] = data[decade][1]
	writer.writerow(record)
