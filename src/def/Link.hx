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
	public var fare:Fare;
	
	// complementary parameter
	public var capacity:Volume; // not used so far
	
	// result
	public var volume:LinkVolume;

}

abstract LinkId( Int ) from Int to Int {

}
