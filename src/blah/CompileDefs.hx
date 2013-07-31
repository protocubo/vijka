package blah;

import def.Cost;
import def.Dist;
import def.Link;
import def.LinkVolume;
import def.Node;
import def.ODSurvey;
import def.Section;
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
		v.set( Auto, 10 );
		v.set( LargeTruck, 10 );
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
