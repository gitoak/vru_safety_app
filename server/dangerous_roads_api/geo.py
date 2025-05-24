import geopandas as gpd
from shapely.geometry import Point

RADIUS_TO_CHECK = 50
SHAPE_FILE_PATH = "data/regensburg_dangerous_streets.shp"

dangerous_roads = None


def load_map():
    global dangerous_roads
    dangerous_roads = gdf = gpd.read_file(SHAPE_FILE_PATH).to_crs(epsg=3857)


def get_dangerous_roads(lat: float, lon: float):
    point = gpd.GeoSeries(Point(lon, lat), crs="EPSG:4326")
    point = point.to_crs(epsg=3857)

    circle = point.buffer(RADIUS_TO_CHECK)  # 100 meter radius
    intersecting_roads = dangerous_roads[dangerous_roads.intersects(
        circle.iloc[0])]

    road_geometries = intersecting_roads.geometry.tolist()
    return road_geometries
