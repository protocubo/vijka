package blah;

import def.CargoType;
import def.Cost;
import def.Dist;
import def.ExpansionFactor;
import def.Link;
import def.LinkVolume;
import def.Node;
import def.ODSurvey;
import def.Speed;
import def.Time;
import def.Toll;
import def.UserCostModel;
import def.VehicleClass;
import def.Volume;

class CompileDefs {
	function new() {
		var dval:Dist = 10;
		trace( dval );
		var tval:Time = 10;
		trace( tval );
		// dval = dval/tval; // EXPECTED compile error
		var vval:SpeedValue = dval/tval;
		trace( vval );
		var v = new Speed();
		v.set( new VehicleClass( 1, 1, 1, "Auto"), 10 );
		v.set( new VehicleClass( 8, 8, 8, "Large truck with 8 axis"), 10 );
		trace( v );

		var fval:Toll = 5;
		var u = new UserCostModel( 10, 5, 15 );
		trace( u.a*dval + ( u.b_social + u.b_operational )*tval );
		// trace( u.b*dval + u.a*tval ); // EXPECTED compile error
	}

	static function main() {
		var app = new CompileDefs();
	}
}
