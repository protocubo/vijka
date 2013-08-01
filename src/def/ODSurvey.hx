package def;

/* 
 * O/D survey interview data.
 */
class ODSurvey {

	public var id:ODSurveyId;

	// TODO lot
	// TODO survey post
	// TODO survey post direction

	public var vehicleClass:VehicleClass;
	public var cargoType:CargoType;

	public var from:Node;
	public var to:Node;
	public var costModel:UserCostModel;

	public var expansionFactor:ExpansionFactor;

	public function new( _id, _vehicleClass, _cargoType, _from, _to, _costModel, ?_expansionFactor=1. ) {
		id = _id;

		vehicleClass = _vehicleClass;
		cargoType = _cargoType;
		
		from = _from;
		to = _to;
		costModel = _costModel;

		expansionFactor = _expansionFactor;
	}
	
}

/* 
 * O/D survey interview identifier.
 */
abstract ODSurveyId( Int ) from Int to Int {

}
