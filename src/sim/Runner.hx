package sim;

import Lambda.has;

import sim.Simulator;

import sim.Simulator.print;
import sim.Simulator.printHL;
import sim.Simulator.println;

class Runner {

	private var idFilter:Null<Array<Int>>;
	private var lotFilter:Null<Array<Int>>;
	private var sectionFilter:Null<Array<Int>>;
	private var directionFilter:Null<Array<Int>>;
	private var vehicleFilter:Null<Array<Int>>;
	private var cargoFilter:Null<Array<String>>;

	function new( _idFilter:Null<Array<Int>>, _lotFilter:Null<Array<Int>>
	, _sectionFilter:Null<Array<Int>>, _directionFilter:Null<Array<Int>>
	, _vehicleFilter:Null<Array<Int>>, _cargoFilter:Null<Array<String>> ) {
		idFilter = _idFilter;
		lotFilter = _lotFilter;
		sectionFilter = _sectionFilter;
		directionFilter = _directionFilter;
		cargoFilter = _cargoFilter;
	}

	public static function parse( idFilter:String, lotFilter:String
	, sectionFilter:String, directionFilter:String, vehicleFilter:String, cargoFilter:String ):Runner {
		return new Runner( parseIntFilter( idFilter )
		, parseIntFilter( lotFilter ), parseIntFilter( sectionFilter )
		, parseIntFilter( directionFilter ), parseIntFilter( vehicleFilter )
		, parseStringFilter( cargoFilter ) );
	}

	public function run( sim:Simulator, volumes:Bool, paths:Bool ) {
		for ( od in getOds( sim ) ) {
			trace( "Running O/D id "+od.id );
			var fexpMulti = 1.; // TODO
			sim.state.digraph.run( od );
			if ( volumes || paths )
				sim.state.digraph.getMoreResults( od, fexpMulti, paths );
		}
	}

	public function showQuery():String {
		var q = [];
		if ( idFilter != null ) q.push( "id IN ("+idFilter.join(",")+")" );
		if ( lotFilter != null ) q.push( "id IN ("+lotFilter.join(",")+")" );
		if ( sectionFilter != null ) q.push( "id IN ("+sectionFilter.join(",")+")" );
		if ( directionFilter != null ) q.push( "id IN ("+directionFilter.join(",")+")" );
		if ( vehicleFilter != null ) q.push( "id IN ("+vehicleFilter.join(",")+")" );
		if ( cargoFilter != null ) q.push( "id IN (\""+cargoFilter.join("\",\"")+"\")" );
		return q.length > 0 ? "WHERE "+q.join( " AND " ) : "*";
	}

	private function getOds( sim:Simulator ):Array<elebeta.ett.rodoTollSim.OD> {
		var filtered = [];
		for ( od in sim.state.ods )
			if ( ( idFilter == null || has(idFilter,od.id) )
			&& ( lotFilter == null || has(lotFilter,od.lot) )
			&& ( sectionFilter == null || has(sectionFilter,od.section) )
			&& ( directionFilter == null || has(directionFilter,od.direction) )
			&& ( vehicleFilter == null || has(vehicleFilter,od.vehicleId) )
			&& ( cargoFilter == null || has(cargoFilter,od.cargo) ) ) {
				filtered.push( od );
			}
		return filtered;
	}

	private static function parseIntFilter( f:String ):Array<Int> {
		if ( f == "_" )
			return null;
		else  {
			var cinp = new format.csv.Reader( new haxe.io.StringInput( f ), "\n", ',', "\"", false );
			var filter = cinp.readRecord().map( Std.parseInt );
			cinp.close();
			return filter;
		}
	}

	private static function parseStringFilter( f:String ):Array<String> {
		if ( f == "_" )
			return null;
		else  {
			var cinp = new format.csv.Reader( new haxe.io.StringInput( f ), "\n", ',', "\"", false );
			var filter = cinp.readRecord();
			cinp.close();
			return filter;
		}
	}

}
