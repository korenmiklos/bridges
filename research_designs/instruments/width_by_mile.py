import json
import csv
from shapely.geometry import shape, Point, LineString, Polygon, MultiPoint, MultiPolygon
from shapely import speedups
import sys, math
from project_geojson import ProjectedFeature
from quadtree import QuadTree, Feature, point_in_rectangle

def get_angle(pt1, pt2):
    x_diff = pt2.x - pt1.x
    y_diff = pt2.y - pt1.y
    return math.degrees(math.atan2(y_diff, x_diff))

## start and end points of chainage tick
## get the first end point of a tick
def get_perpendicular_segment(pt, bearing, length):
    angle = bearing + 90
    bearing = math.radians(angle)
    x1 = pt.x + 0.5*length*math.cos(bearing)
    y1 = pt.y + 0.5*length*math.sin(bearing)
    x2 = pt.x - 0.5*length*math.cos(bearing)
    y2 = pt.y - 0.5*length*math.sin(bearing)
    return LineString([(x1, y1), (x2, y2)])

def disc_5km(geometry_in_meters):
    return geometry_in_meters.buffer(5000.0)

def perpendicular_ticks(line_in_meters, step=10000.0, length=5000.0):
    length = line_in_meters.length
    previous_distance_covered = 0.0
    lines = []
    for point1, point2 in zip(line_in_meters.coords, line_in_meters.coords[1:]):
        p1 = Point(point1)
        if line_in_meters.project(p1) >= previous_distance_covered +  step:
            p2 = Point(point2)
            bearing = get_angle(p1, p2)
            tick = get_perpendicular_segment(p1, bearing, length)
            previous_distance_covered += step
            lines.append(dict(river_mile=int(previous_distance_covered/1609.3), geometry=tick))
    return lines

def get_every_10k_points(line_in_meters, step=10000.0):
    length = line_in_meters.length
    covered = 0
    points = []
    while covered<length:
        points.append(dict(river_mile=int(covered/1609.3), geometry=line_in_meters.interpolate(covered)))
        covered += step
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

river_line_meters = ProjectedFeature(json.load(open("input/rivers/%s/river_midline.geojson" % river))['features'][0]['geometry'], 'wgs84').lcc
ticks = perpendicular_ticks(river_line_meters, step=1609.3, length=5000.0)
water_body_fc = json.load(open("input/rivers/%s/river_poly.geojson" % river))
water_body = ProjectedFeature(feature_collection_to_multipolygon(water_body_fc), projection='epsg3975').lcc

writer = csv.DictWriter(sys.stdout, fieldnames=['river_mile', 'river_width'])
writer.writeheader()

for segment in ticks:
    river_width = segment['geometry'].intersection(water_body.buffer(0)).length
    writer.writerow(dict(river_mile=segment['river_mile'], 
        river_width=river_width,
        ))
