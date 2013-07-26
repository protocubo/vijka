package def;

class Node {
	public var id:NodeId;
	public var x:Float;
	public var y:Float;
	public function new( _id, _x, _y ) {
		id = _id;
		x = _x;
		y = _y;
	}
}

abstract NodeId( Int ) from Int to Int {

}
