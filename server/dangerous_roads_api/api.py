from flask import Flask, jsonify, request
import geo
from datetime import datetime

app = Flask(__name__)


with app.app_context():
    geo.load_map()


@app.route('/is_dangerous_road_nearby', methods=['GET'])
def handle_coordinate():
    s = datetime.now().strftime("%H:%M:%S")
    print(f"[{s}] received request by {request.remote_addr}")

    if 'coord' not in request.args:
        return jsonify({"success": False}), 400

    coord = request.args.get('coord')

    try:
        lat = float(coord.split(",")[0])
        lon = float(coord.split(",")[1])
    except (ValueError, IndexError):
        return jsonify({"success": False}), 400

    print(f"[{s}] got coordinations by {request.remote_addr}: {lat}, {lon}")
    dangerous_roads = geo.get_dangerous_roads(lat, lon)
    if not dangerous_roads:
        return jsonify({'success': True, 'dangerous_roads_nearby': False})
    else:
        print(f"[{s}] found dangerous roads nearby: {dangerous_roads}")
        return jsonify({'success': True, 'dangerous_roads_nearby': True})


if __name__ == '__main__':
    app.run(port=5000)
