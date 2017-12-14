import json
import csv
from shapely.geometry import shape, Point, LineString, Polygon, MultiPoint, MultiPolygon, mapping
from shapely import speedups
import sys, math
from project_geojson import ProjectedFeature
from quadtree import QuadTree, Feature, point_in_rectangle

def river_bank(geometry_in_meters, distance=5000.0):
    return geometry_in_meters.buffer(distance)


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

def simple_count(multi_point, polygon):
    inside = polygon.intersection(multi_point)
    if inside.is_empty:
        return 0
    elif inside.geom_type=='Point':
        return 1
    else:
        return len(inside.geoms)

speedups.enable()

river = sys.argv[1]

geojson = json.load(open("input/us-postal-history/postoffices.geojson"))

# convert all post office coordinates to LCC
features = []
for point in geojson['features']:
    point['geometry'] = mapping(ProjectedFeature(point['geometry'], 'wgs84').lcc)

post_offices = QuadTree(geojson['features'])


river_line_meters = ProjectedFeature(json.load(open("input/rivers/%s/river_midline.geojson" % river))['features'][0]['geometry'], 'wgs84').lcc
water_body_fc = json.load(open("input/rivers/%s/river_poly.geojson" % river))
water_body = Feature(geometry=river_bank(ProjectedFeature(feature_collection_to_multipolygon(water_body_fc), projection='epsg3975').lcc))

relevant_post_offices = post_offices.get_overlapping_points(water_body)

writer = csv.DictWriter(sys.stdout, fieldnames=['river_mile', 'po_from', 'po_to', 'distance_to_river'])
writer.writeheader()

for po in relevant_post_offices:
    point = shape(po['geometry'])
    row = {}
    row['river_mile'] = river_line_meters.project(point)/1609.3
    # distance to water body polygon in meters
    row['distance_to_river'] = point.distance(ProjectedFeature(feature_collection_to_multipolygon(water_body_fc), projection='epsg3975').lcc)
    row['po_from'] = po['properties']['from']
    row['po_to'] = po['properties']['to']

    writer.writerow(row)
