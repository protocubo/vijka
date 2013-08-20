package elebeta.ett.rodoTollSim;

import format.ett.Data;
import format.ett.Geometry;

class LinkShape {
	public var id:Int;
	public var shape:LineString;

	public inline function geojsonGeometry():String {
		return shape.geoJSONString();
	}

	public static function ettFields():Array<Field> {
		return [
			new Field( "id", TInt ),
			new Field( "shape", TGeometry(TLineString) )
		];
	}

	public static function makeEmpty():LinkShape {
		return new LinkShape();
	}

	public static function make( id, shape ):LinkShape {
		var shp = new LinkShape();
		shp.id = id;
		shp.shape = shape;
		return shp;
	}

	private function new() {}

}
