import json
import csv
from quadtree import QuadTree, Feature, point_in_rectangle
from shapely.geometry import shape, Polygon 
from shapely import speedups
import sys
from project_geojson import ProjectedFeature

speedups.enable()

river = sys.argv[1]
decades = [str(year) for year in range(1790,1960,10)]

geojson = json.load(open("../../data/us-postal-history/consistent/postoffices.geojson"))
bridges = json.load(open("../../data/rivers/%s/bridges.geojson" % river))['features']
left_bank = json.load(open("../../data/rivers/%s/left_bank.geojson" % river))['geometry']
right_bank = json.load(open("../../data/rivers/%s/right_bank.geojson" % river))['geometry']

keep = ['name', 'start', 'river_mile']
writer = csv.DictWriter(sys.stdout, fieldnames=keep+['left_%s' % decade for decade in decades]+['right_%s' % decade for decade in decades])
writer.writeheader()

post_offices = QuadTree(geojson['features'])

for bridge in bridges:
	bridge_disc = ProjectedFeature(ProjectedFeature(bridge['geometry'], 'wgs84').lcc.buffer(10000.0), 'lcc').wgs84
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
