package spod;

import sys.db.Types;

class Link extends sys.db.Object {
	public var id:SId;

	@:relation( fromId ) public var start:Node;
	@:relation( toId ) public var finish:Node;

	public var dist:Float;
	public var speed:Float;
	public var toll:Null<Float>;

	public var capacity:Float;
}
