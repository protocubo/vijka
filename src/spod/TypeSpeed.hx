package spod;

import sys.db.Types;

@:id( typeId, vclassNoAxis )
class TypeSpeed extends sys.db.Object {

	@:relation( typeId ) public var type:LinkType;
	@:relation( vclassNoAxis ) public var vlcass:VehicleClass;
	public var speed:SFloat;

}
