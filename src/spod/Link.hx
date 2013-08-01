package spod;

import sys.db.Types;

class Link extends sys.db.Object {

	public var id:SId;

	@:relation( fromId ) public var start:Node;
	@:relation( toId ) public var finish:Node;

	public var dist:SFloat;
	@:relation( typeId ) public var type:LinkType;
	public var toll:SFloat;

	public var data:SData<Dynamic>;

}
