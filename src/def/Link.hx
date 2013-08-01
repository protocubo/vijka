package def;

/* 
 * Network link.
 * 
 * On the database this will probably be split in link, link type and
 * link overulings.
 */
class Link {

	// entity id
	public var id:LinkId;
	
	// relation to nodes
	public var start:Node;
	public var finish:Node;

	// parameters
	public var dist:Dist;
	public var speed:Speed;
	public var toll:Toll;
	
	// complementary parameters
	// public var capacity:Volume; // not used yet
	
	// result
	// public var volume:Null<LinkVolume>; // not used yet

	public function new( _id, _start, _finish, _dist, _speed, _toll ) {
		id = _id;
		start = _start;
		finish = _finish;
		dist = _dist;
		speed = _speed;
		toll = _toll;
	}

}

/* 
 * Link identifier.
 */
abstract LinkId( Int ) from Int to Int {

}
