package elebeta.ett.vijka;

import format.ett.Data;
import format.ett.Geometry;

class LinkShape {
	
	public var linkId:Int;
	public var shape:LineString;

	public inline function geojsonGeometry():String {
		return shape.geoJSONString();
	}

	public static function ettFields():Array<Field> {
		return [
			new Field( "linkId", TInt ),
			new Field( "shape", TGeometry(TLineString) )
		];
	}

	public static inline function makeEmpty():LinkShape {
		return new LinkShape();
	}

	public static inline function make( linkId, shape ):LinkShape {
		var shp = new LinkShape();
		shp.linkId = linkId;
		shp.shape = shape;
		return shp;
	}

	private inline function new() {}

}
