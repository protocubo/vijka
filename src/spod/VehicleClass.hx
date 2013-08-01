package spod;

import sys.db.Types;

@:id( noAxis )
class VehicleClass extends sys.db.Object {

	public var noAxis:SInt;
	public var tollMulti:SFloat;
	public var equiv:SFloat;

	public var name:SText;

	public var data:SData<Dynamic>;

}
