package def;

class Link {

	// entity
	public var id:LinkId;
	
	// relation
	public var start:Node;
	public var finish:Node;

	// parameter
	public var dist:Dist;
	public var speed:Speed;
	public var toll:Null<Toll>;
	
	// complementary parameter
	public var capacity:Volume; // not used so far
	
	// result
	public var volume:Null<LinkVolume>;

	public function new( _id, _start, _finish, _dist, _speed, _toll, _capacity ) {
		id = _id;
		start = _start;
		finish = _finish;
		dist = _dist;
		speed = _speed;
		toll = _toll;
	}

}

abstract LinkId( Int ) from Int to Int {

}
