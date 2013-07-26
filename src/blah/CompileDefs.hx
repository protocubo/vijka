package blah;

import def.Dist;
import def.Time;
import def.Speed;

import def.Cost;
import def.Fare;
import def.UserCost;

import def.VehicleClass;

import def.Section;
import def.ODSurvey;

import def.Node;
import def.Link;

import def.Volume;
import def.LinkVolume;

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

		var fval:Fare = 5;
		var u = new UserCost( 10, 20 );
		trace( u.a*dval + u.b*tval );
		// trace( u.b*dval + u.a*tval ); // EXPECTED compile error
	}

	static function main() {
		var app = new CompileDefs();
	}
}
