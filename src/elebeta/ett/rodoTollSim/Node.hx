package elebeta.ett.rodoTollSim;

import format.ett.Data;
import format.ett.Geometry;

class Node {

	public var id:Int;
	public var point:Point;

	public function geoJSONString( ?propJSON:String ):String {
		if ( propJSON == null ) propJSON = '{"id":$id}';
		return '{"id":$id,"type":"Feature","geometry":${point.geoJSONString()},"properties":$propJSON}';
	}

	public static function ettFields():Array<Field> {
		return [
			new Field( "id", TInt ),
			new Field( "point", TGeometry(TPoint) )
		];
	}

	public static function makeEmpty():Node {
		return new Node();
	}

	public static function make( id, point ):Node {
		var node = new Node();
		node.id = id;
		node.point = point;
		return node;
	}

	private function new() {}

}
