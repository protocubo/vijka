package def;

class ODSurvey {

	public var from:Node;
	public var to:Node;
	public var vehicleClass:VehicleClass;
	
	public var section:Section;
	
	public var cost:UserCost;

	public function new( _from, _to, _cost ) {
		from = _from;
		to = _to;
		cost = _cost;
	}
	
}
