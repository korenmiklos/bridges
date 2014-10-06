import pyproj
from shapely.ops import transform
from shapely.geometry.base import BaseGeometry
from shapely.geometry import asShape

from shapely.geometry import Point

PROJECTIONS = dict(
	wgs84 = pyproj.Proj("+init=EPSG:4326"),
	lcc = pyproj.Proj(proj="lcc"),
	nhgis = pyproj.Proj("+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"),
    epsg3975 = pyproj.Proj("+proj=cea +lon_0=0 +lat_ts=30 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
)

def project_geometry(geometry, tfrom, tto):
	return transform(lambda x, y: pyproj.transform(PROJECTIONS[tfrom], PROJECTIONS[tto], x, y), geometry)

class ProjectedFeature(object):
    def __init__(self, geometry, projection):
        '''
        Every incoming geometry (point, linestring, polygon) is stored in wgs84.
        '''
        if not isinstance(geometry, BaseGeometry):
            # if not shapely geometry, treat as geojson dictionary
            geometry = asShape(geometry)
    	self.geometry = project_geometry(geometry, projection, 'wgs84')

    def __getattr__(self, projection):
        '''
        We can refer to projected features as an attribute, e.g.

            feature.wgs84
            feature.lcc
        '''
        if projection in PROJECTIONS:
            return project_geometry(self.geometry, 'wgs84', projection)
        else:
            raise AttributeError

if __name__ == '__main__':      
    union_sq = Point((1827011,574994))
    union_sq_geojson = {
        "type": "Point",
        "coordinates": [1827011, 574994]
    }

    Union_Sq = ProjectedFeature(union_sq, 'nhgis')
    print Union_Sq.wgs84
    print Union_Sq.lcc

    Union_Sq = ProjectedFeature(union_sq_geojson, 'nhgis')
    print Union_Sq.wgs84
