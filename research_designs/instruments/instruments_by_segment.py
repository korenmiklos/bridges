import json
import csv
from shapely.geometry import shape, Polygon, MultiPoint, MultiPolygon
from shapely import speedups
import sys
from project_geojson import ProjectedFeature
from quadtree import QuadTree, Feature, point_in_rectangle

def disc_10km(geometry_in_meters):
	return geometry_in_meters.buffer(10000.0)

def get_every_10k_points(line_in_meters):
	length = line_in_meters.length
	covered = 0
	points = []
	while covered<length:
		points.append(dict(river_mile=int(covered/1600.0), geometry=line_in_meters.interpolate(covered)))
		covered += 10000.0
	return points

def polygonize(geometry):
	g = shape(geometry)
	if g.geom_type=='MultiPolygon':
		return [poly.buffer(0.0) for poly in g.geoms]
	else:
		return [g.buffer(0.0)]

def feature_collection_to_multipolygon(fc):
	list_of_polygons = []
	for feature in fc['features']:
		poly = polygonize(feature['geometry'])
		list_of_polygons.extend(poly)
	return MultiPolygon(list_of_polygons)

speedups.enable()

river = sys.argv[1]

geojson = json.load(open("../../data/us-postal-history/consistent/postoffices.geojson"))
points = []
for point in geojson['features']:
	projected = ProjectedFeature(point['geometry'], projection='wgs84').lcc
	points.append((projected.x, projected.y))
post_offices = QuadTree(points)


river_line_meters = ProjectedFeature(json.load(open("../../data/rivers/%s/river.geojson" % river))['features'][0]['geometry'], 'wgs84').lcc
bridges = json.load(open("../../data/rivers/%s/bridges.geojson" % river))['features']
bridge_collection = ProjectedFeature(MultiPoint([shape(bridge['geometry']) for bridge in bridges]), projection='wgs84').lcc
segments = [dict(river_mile=point['river_mile'], 
	geometry=disc_10km(point['geometry'])) for point in get_every_10k_points(river_line_meters)]
water_body_fc = json.load(open("../../data/rivers/%s/river_poly.geojson" % river))
water_body = ProjectedFeature(feature_collection_to_multipolygon(water_body_fc), projection='epsg3975').lcc

writer = csv.DictWriter(sys.stdout, fieldnames=['river_mile', 'water_covered_area', 'bridges', 'post_office_count'])
writer.writeheader()

for segment in segments:
	water_covered_area = segment['geometry'].intersection(water_body.buffer(0)).area
	bridges = segment['geometry'].intersection(bridge_collection)
	post_office_count = post_offices.count_overlapping_points(Feature(geometry=segment['geometry']))
	if bridges.is_empty:
		number = 0
	elif bridges.geom_type=='Point':
		number = 1
	else:
		number = len(bridges.geoms)
	writer.writerow(dict(river_mile=segment['river_mile'], 
		water_covered_area=water_covered_area/segment['geometry'].area,
		bridges=number,
		post_office_count=post_office_count))
