package sim;

import elebeta.ett.rodoTollSim.*;
import format.ett.Data.Encoding in ETTEncoding;
import format.ett.Data.Field in ETTField;
import format.ett.Reader;
import format.ett.Writer;
import haxe.io.Eof;
import sys.io.FileInput;
import sys.io.FileOutput;

import jonas.NumberPrinter.printDecimal;
import Lambda.array;
import Lambda.count;
import Lambda.filter;
import Lambda.has;
import Lambda.list;
import Std.parseFloat;
import Std.parseInt;
import Std.string;

import sim.Algorithm;
import sim.col.LinkTypeSpeedMap;
import sim.Query;

import sim.Simulator.print;
import sim.Simulator.printHL;
import sim.Simulator.println;

class SimulatorAPI extends mcli.CommandLine {

	private var reading:Bool;
	private var sim:Simulator;

	public function new( _sim:Simulator, _reading:Bool ) {
		sim = _sim;
		reading = _reading;
		super();
	}



	// NODE I/O -----------------------------------------------------------------

	/**
		Read nodes from Node ETT in `path` (reentrant)
	**/
	public function readNodes( path:String ) {
		if ( sim.state.nodes == null ) {
			println( "Reading nodes" );
			sim.state.nodes = new Map();
		}
		else {
			println( "Reading additional nodes" );
			println( "Existing nodes may have been changed, consider verifying link shapes" );
		}
		var nodes = sim.state.nodes; // just a shortcut
		var einp = readEtt( path );
		sim.state.invalidate();
		while ( true ) {
			var node = try { einp.fastReadRecord( Node.makeEmpty() ); }
			           catch ( e:Eof ) { null; };
			if ( node == null ) break;
			nodes.set( node.id, node );
		}
		einp.close();
	}

	/**
		Count nodes
	**/
	public function countNodes() {
		var cnt = sim.state.nodes != null ? count( sim.state.nodes ) : 0;
		println( "Counted "+cnt+" nodes" );
	}



	// LINK TYPE I/O ------------------------------------------------------------

	/**
		Read link types from LinkType ETT in `path` (reentrant)
	**/
	public function readTypes( path:String ) {
		if ( sim.state.linkTypes == null ) {
			println( "Reading link types" );
			sim.state.linkTypes = new Map();
		}
		else {
			println( "Reading additional link types" );
		}
		var linkTypes = sim.state.linkTypes; // just a shortcut
		var einp = readEtt( path );
		while ( true ) {
			var type = try { einp.fastReadRecord( LinkType.makeEmpty() ); }
			           catch ( e:Eof ) { null; };
			if ( type == null ) break;
			linkTypes.set( type.id, type );
		}
		einp.close();
	}

	/**
		Show link types
	**/
	public function showTypes() {
		println( "Known types:" );
		println( right("id",6)+"  |  name" );
		printHL( "-" );
		for ( type in sim.state.linkTypes )
			println( right(type.id,6)+"  |  "+type.name );
	}

	/**
		Count link types
	**/
	public function countTypes() {
		var cnt = sim.state.linkTypes != null ? count( sim.state.linkTypes ) : 0;
		println( "Counted "+cnt+" link types" );
	}



	// LINK I/O -----------------------------------------------------------------

	/**
		Read links from Link ETT in `path` (reentrant); requires nodes and link
		types; extensions should be in km
	**/
	public function readLinks( path:String ) {
		if ( sim.state.links == null ) {
			println( "Reading links" );
			sim.state.links = new Map();
		}
		else {
			println( "Reading additional links" );
		}
		var nodes = sim.state.nodes; // just a shortcut
		var links = sim.state.links; // just a shortcut
		var linkTypes = sim.state.linkTypes; // just a shortcut
		if ( nodes == null ) throw "No nodes";
		if ( linkTypes == null ) throw "No link types";
		var einp = readEtt( path );
		sim.state.invalidate();
		while ( true ) {
			var link = try { einp.fastReadRecord( Link.makeEmpty() ); }
			           catch ( e:Eof ) { null; };
			if ( link == null ) break;
			if ( !nodes.exists( link.startNodeId ) )
				throw "Missing node "+link.startNodeId;
			if ( !nodes.exists( link.finishNodeId ) )
				throw "Missing node "+link.finishNodeId;
			if ( !linkTypes.exists( link.typeId ) )
				throw "Missing link type "+link.typeId;
			links.set( link.id, link );
		}
		einp.close();
	}

	/**
		Count links
	**/
	public function countLinks() {
		var cnt = sim.state.links != null ? count( sim.state.links ) : 0;
		println( "Counted "+cnt+" links" );
	}

	/**
		Write links to GeoJSON in `path` using available link shape data; accepts
		(optionnally) a unified `filter` query; will overwrite existing files
	**/
	public function geojsonLinks( path:String, ?filter:String ) {
		println( "Mapping volumes in GeoJSON" );
		var links = sim.state.links; // just a shortcut
		if ( links == null ) throw "No links";
		var fout = writeFile( path, false );
		fout.writeString( '{"type":"FeatureCollection","features":['+sim.newline );
		var first = true;
		if ( filter == null ) {
			for ( k in links ) {
				if ( first ) first = false; else fout.writeString( ","+sim.newline+"\t" );
				fout.writeString( geojsonLink( k ) );
			}
		}
		else {
			var aliases = sim.state.aliases;
			var q = Query.prepare( filter, "id" );
			for ( k in q.execute( links, aliases ) ) {
				if ( first ) first = false; else fout.writeString( ","+sim.newline+"\t" );
				fout.writeString( geojsonLink( k ) );
			}
		}
		fout.writeString( sim.newline+"] }"+sim.newline );
		fout.close();
	}



	// LINK SHAPE I/O -----------------------------------------------------------

	/**
		Read link shape from LinkShape ETT in `path` (reentrant); shapes for
		unknown links are just ignored
	**/
	public function readShapes( path:String ) {
		if ( sim.state.shapes == null ) {
			println( "Reading link shapes" );
			sim.state.shapes = new Map();
		}
		else {
			println( "Reading additional link shapes; overwriting when necessary" );
		}
		var links = sim.state.links; // just a shortcut
		if ( links == null || !links.iterator().hasNext() )
			return; // no links
		var shapes = sim.state.shapes; // just a shortcut
		var einp = readEtt( path );
		while ( true ) {
			var shape = try { einp.fastReadRecord( LinkShape.makeEmpty() ); }
			           catch ( e:Eof ) { null; };
			if ( shape == null ) break;
			if ( links.exists( shape.id ) )
				shapes.set( shape.id, shape );
		}
		einp.close();
	}

	/**
		Count links with custom shapes
	**/
	public function countShapes() {
		var cnt = sim.state.shapes != null ? count( sim.state.shapes ) : 0;
		println( "Counted "+cnt+" links with custom shapes" );
	}

	/**
		Compress link shapes; removes all shapes redundant with the default ones
		(that are based on start and finish nodes)
	**/
	public function compressShapes() {
		var oldShapes = sim.state.shapes; // just a shortcut
		if ( oldShapes == null )
			return;
		println( "Compressing link shape data" );
		var shapes = new Map();
		for ( s in oldShapes )
			if ( s.shape.length > 2 )
				shapes.set( s.id, s );
		sim.state.shapes = shapes;
		println( "All shapes with only 2 points have been removed" );
	}

	/**
		Clear link shapes; when necessary the default ones (that are based on
		start and finish nodes)
	**/
	public function clearShapes() {
		if ( sim.state.shapes != null ) {
			println( "Clearing link shape data; default shapes will be used" );
			sim.state.shapes = null;
		}
	}



	// LINK ALIASES -------------------------------------------------------------

	/**
		Read link aliases from LinkAlias ETT in `path` (reentrant); aliases for
		unknown links are just ignored
	**/
	public function readAliases( path:String ) {
		if ( sim.state.aliases == null ) {
			println( "Reading link aliases" );
			sim.state.aliases = new Map();
		}
		else {
			println( "Reading additional link aliases; overwriting when necessary" );
		}
		var links = sim.state.links; // just a shortcut
		if ( links == null || !links.iterator().hasNext() )
			return; // no links
		var aliases = sim.state.aliases; // just a shortcut
		var einp = readEtt( path );
		while ( true ) {
			var alias = try { einp.fastReadRecord( LinkAlias.makeEmpty() ); }
			           catch ( e:Eof ) { null; };
			if ( alias == null ) break;
			if ( links.exists( alias.linkId ) )
				if ( aliases.exists( alias.name ) )
					aliases.get( alias.name ).push( alias.linkId );
				else
					aliases.set( alias.name, [ alias.linkId ] );
		}
		einp.close();
	}



	// VEHICLE I/O --------------------------------------------------------------

	/**
		Read vehicles from Vehicle ETT in `path` (reentrant)
	**/
	public function readVehicles( path:String ) {
		if ( sim.state.vehicles == null ) {
			println( "Reading vehicles" );
			sim.state.vehicles = new Map();
		}
		else {
			println( "Reading additional vehicles" );
		}
		var vehicles = sim.state.vehicles; // just a shortcut
		var einp = readEtt( path );
		sim.state.invalidate(); // this might (and should) not be necessary in the future
		while ( true ) {
			var type = try { einp.fastReadRecord( Vehicle.makeEmpty() ); }
			           catch ( e:Eof ) { null; };
			if ( type == null ) break;
			vehicles.set( type.id, type );
		}
		einp.close();
	}

	/**
		Show vehicles
	**/
	public function showVehicles() {
		println( "Known types:" );
		println( right("id",6)+"  |  name" );
		printHL( "-" );
		for ( type in sim.state.vehicles )
			println( right(type.id,6)+"  |  "+type.name );
	}

	/**
		Count vehicles
	**/
	public function countVehicles() {
		var cnt = sim.state.vehicles != null ? count( sim.state.vehicles ) : 0;
		println( "Counted "+cnt+" vehicles" );
	}



	// LINK TYPE SPEED I/O ------------------------------------------------------

	/**
		Read speeds for (link type,vehicle) pairs from LinkTypeSpeed ETT in `path`
		(reentrant); requires link types and vehicles; speeds should be in km/h
	**/
	public function readSpeeds( path:String ) {
		if ( sim.state.speeds == null ) {
			println( "Reading link type speeds" );
			sim.state.speeds = new LinkTypeSpeedMap();
		}
		else {
			println( "Reading additional link type speeds" );
		}
		var linkTypes = sim.state.linkTypes; // just a shortcut
		var vehicles = sim.state.vehicles; // just a shortcut
		if ( linkTypes == null ) throw "No link types";
		if ( vehicles == null ) throw "No vehicles";
		var speeds = sim.state.speeds; // just a shortcut
		var einp = readEtt( path );
		sim.state.invalidate(); // this might (and should) not be necessary in the future
		while ( true ) {
			var speed = try { einp.fastReadRecord( LinkTypeSpeed.makeEmpty() ); }
			            catch ( e:Eof ) { null; };
			if ( speed == null ) break;
			if ( !linkTypes.exists( speed.typeId ) )
				throw "Missing link type "+speed.typeId;
			if ( !vehicles.exists( speed.vehicleId ) )
				throw "Missing vehicle "+speed.vehicleId;
			speeds.set( speed, speed );
		}
		einp.close();
	}

	/**
		Show speeds for type id `type-id` and vehicle id `vehicle-id`;
		id set to "_" will be treated as non restrictive filters
	**/
	public function showSpeeds( tid:String, vid:String ) {
		var t:Null<Int> = readInt( tid );
		var v:Null<Int> = readInt( vid );
		print( "Link speeds for " );
		print( t != null ? " typeId="+t+" " : "all link types " );
		println( v != null ? " vehicleId="+v+" " : "all vehicles:" );
		println( right("type",6)+"  |  "+right("vehicle",8)+"  |  speed (km/h" );
		printHL( "-" );
		// TODO get typeId,vehicleId from the other collections and show missing values
		if ( sim.state.speeds == null )
			throw "No speeds";
		var speeds = [ for ( s in sim.state.speeds ) s ];
		speeds.sort( function (a,b) return 2*Reflect.compare(a.typeId,b.typeId)+Reflect.compare(a.vehicleId,b.vehicleId) );
		for ( speed in speeds )
			if ( ( t == null || speed.typeId == t )
			&& ( v == null || speed.vehicleId == v ) )
				println( right(speed.typeId,6)+"  |  "+right(speed.vehicleId,8)+"  |  "+speed.speed );
	}



	// OD I/O -----------------------------------------------------------------

	/**
		Read O/D data from OD ETT in `path` (reentrant); requires vehicles; costs
		should be in $/km (distance multipliers) and and $/h (time multipliers);
		when applicable, custom sample weights may be reset
	**/
	public function readOd( path:String ) {
		if ( sim.state.ods == null ) {
			println( "Reading O/D data" );
			sim.state.ods = new Map();
		}
		else {
			println( "Reading additional O/D data" );
			sim.state.activeOds = null;
			sim.state.activeOdFilter = null;
		}
		var vehicles = sim.state.vehicles; // just a shortcut
		var ods = sim.state.ods; // just a shortcut
		var wgts = sim.state.sampleWeights;
		if ( vehicles == null ) throw "No vehicles";
		var einp = readEtt( path );
		while ( true ) {
			var od = try { einp.fastReadRecord( OD.makeEmpty() ); }
			         catch ( e:Eof ) { null; };
			if ( od == null ) break;
			if ( !vehicles.exists( od.vehicleId ) )
			if ( !vehicles.exists( od.vehicleId ) )
				throw "Missing vehicle "+od.vehicleId;
			ods.set( od.id, od );
			if ( wgts != null )
				wgts.remove( od.id );
		}
		einp.close();
	}

	/**
		Count O/D data
	**/
	public function countOd() {
		var cnt = sim.state.ods != null ? count( sim.state.ods ) : 0;
		println( "Total O/D records: "+cnt );
		if ( sim.state.activeOds != null )
			println( "Selected O/D records: "+sim.state.activeOds.length );
	}



	// OD FILTERS ---------------------------------------------------------------

	/**
		Filter remaining O/D data (reentrant); supported filter `type`s are "id",
		"lot", "section", "direction", "vehicle" (vehicle id) and "cargo"; `clause`
		may be "_" (no filter), a value or a comma separated list of values
	**/
	public function filterOd( type:String, clause:String ) {
		var ods = sim.state.ods;
		if ( ods == null ) throw "No O/D data";
		var activeOds = list( sim.state.activeOds != null ? sim.state.activeOds : sim.state.ods );
		var activeOdFilter = sim.state.activeOdFilter; if ( activeOdFilter == null ) activeOdFilter = [];
		sim.state.activeOds = array( queryOd( activeOds, type, clause, activeOdFilter ) );
		sim.state.activeOdFilter = activeOdFilter;
		println( "Current selected records: "+activeOds.length );
		showOdFilter();
	}

	/**
		Show O/D filter expression
	**/
	public function showOdFilter() {
		if ( sim.state.activeOdFilter == null )
			println( "No O/D filter at the moment... All available data selected" );
		else
			println( "Selected O/D records where "+sim.state.activeOdFilter.join("\n    && ") );
	}

	/**
		Clear O/D filter; reselects all O/D records
	**/
	public function clearOdFilter() {
		sim.state.activeOds = null;
		sim.state.activeOdFilter = null;
	}



	// EXPANSION FACTORS --------------------------------------------------------

	/**
		Alter sample weights according to criteria `type` and `clause` by
		setting them to `value`; any remaining volumes are lost
	**/
	public function setWeight( type:String, clause:String, value:Float ) {
		sim.state.volumes = null;
		if ( sim.state.ods == null )
			throw "No O/D data";
		var exp = sim.state.sampleWeights;
		if ( exp == null )
			exp = sim.state.sampleWeights = new Map();
		var q = queryOd( sim.state.ods, type, clause );
		sim.state.volumes = null;
		for ( od in q )
			exp.set( od.id, value );
	}

	/**
		Alter sample weights according to criteria `type` and `clause` by
		multiplying current values by `multi`; any remaining volumes are lost
	**/
	public function alterWeight( type:String, clause:String, multi:Float ) {
		sim.state.volumes = null;
		if ( sim.state.ods == null )
			throw "No O/D data";
		var exp = sim.state.sampleWeights;
		if ( exp == null )
			exp = sim.state.sampleWeights = new Map();
		var q = queryOd( sim.state.ods, type, clause );
		for ( od in q ) {
			var previous = exp.exists( od.id ) ? exp.get( od.id ) : od.sampleWeight;
			exp.set( od.id, od.sampleWeight*multi );
		}
	}

	/**
		Resets all sample weights to their value on the O/D record; any remaining
		volumes are lost
	**/
	public function resetWeights( type:String, clause:String, multi:Float ) {
		sim.state.volumes = null;
		sim.state.sampleWeights = null;
	}



	// RUNNING ------------------------------------------------------------------

	/**
		Set the algorithm base to `name`; supported algorithms at the moment are
		"Dijstra" and "A*"
	**/
	public function setAlgorithm( name:String ) {
		var algo = switch ( name.toLowerCase() ) {
		case "dijkstra", "ijk", "dijk", "dijstras":
			ADijkstra;
		case "a*", "astar", "a-star", "star":
			AAStar;
		case "bellman-ford", "bford", "bell", "ford":
			ABellmanFord;
			throw "Bellman-Ford algorithm has been disabled";
		case all:
			throw "Unknown algorithm "+all;
		};
		if ( algo != sim.state.algorithm ) {
			var old = algoName( sim.state.algorithm );
			var newName = algoName( algo );
			println( "Changing algorithm from "+old+" to "+newName );
			sim.state.algorithm = algo;
			sim.state.invalidate();
			printHL( "-" );
		}
	}

	/**
		Show the current selected base algorithm
	**/
	public function showAlgorithm() {
		println( "Current algorithm: "+algoName(sim.state.algorithm) );
	}
	private function algoName( a:Algorithm ) {
		return switch ( a ) {
		case ADijkstra: "Dijkstra";
		case AAStar: "A*";
		case ABellmanFord: "Bellman-Ford";
		};
	}

	/**
		Execute/run saving `volumes` and/or `path`
	**/
	public function run( ?volumes:String, ?path:String ) {
		var ods:Iterable<OD> = sim.state.activeOds != null ? sim.state.activeOds : sim.state.ods;
		if ( ods == null ) throw "No O/D data";
		var odCnt = count( ods );
		if ( odCnt == 0 ) {
			println( "No O/D records... Try to remove the filter with --clear-od-filter" );
			return;
		}
		var wgts = sim.state.sampleWeights != null ? sim.state.sampleWeights : null;
		var saveVols = readBool( volumes, true ) != false;
		var savePath = readBool( path, true ) != false;
		assemble();
		if ( sim.state.results == null ) sim.state.results = new Map();
		if ( saveVols && sim.state.volumes == null ) sim.state.volumes = new Map();
		var G = sim.state.digraph;
		if ( saveVols ) println( "Saving link volumes" );
		if ( savePath ) println( "Saving selected paths" );
		showAlgorithm();
		println( "    D-ary heap arity = "+G.heapArity );
		println( "    D-ary heap initial reserve = "+G.heapReserve );
		var lt = haxe.Timer.stamp();
		var i = 0;
		print( "\rRunning "+i+"/"+odCnt );
		for ( od in ods ) {
			var w = od.sampleWeight;
			if ( wgts != null && wgts.exists( od.id ) )
				w = wgts.get( od.id );
			G.run( od, w, saveVols, savePath );
			i++;
			if ( haxe.Timer.stamp() - lt > .2 ) {
				lt = haxe.Timer.stamp();
				print( "\rRunning "+i+"/"+odCnt+" paths" );
			}
		}
		println( "\rRunning "+i+"/"+odCnt+" paths... Done" );
	}

	/**
		Clear all previous results
	**/
	public function clearResults() {
		sim.state.clearResults();
	}



	// VOLUME I/O ---------------------------------------------------------------

	/**
		Write volumes to LinkVolume ETT in `path`; will overwrite existing files
	**/
	public function ettVolumes( path:String ) {
		println( "Writing volumes" );
		var volumes = sim.state.volumes; // just a shortcut
		if ( volumes == null )
			throw "No volumes";
		var eout = writeEtt( LinkVolume, LinkVolume.ettFields(), path );
		for ( v in volumes )
			eout.write( v );
		eout.close();
	}

	/**
		Write volumes to GeoJSON in `path` using available link shape data; will
		overwrite existing files
	**/
	public function geojsonVolumes( path:String ) {
		println( "Mapping volumes in GeoJSON" );
		var volumes = sim.state.volumes; // just a shortcut
		if ( volumes == null ) throw "No volumes";
		var fout = writeFile( path, false );
		fout.writeString( '{"type":"FeatureCollection","features":['+sim.newline );
		var first = true;
		for ( v in volumes ) {
			if ( first ) first = false; else fout.writeString( ","+sim.newline+"\t" );
			fout.writeString( geojsonVolume( v ) );
		}
		fout.writeString( sim.newline+"] }"+sim.newline );
		fout.close();
	}

	

	// RESULTS I/O --------------------------------------------------------------

	/**
		Write results to ODResults ETT in `path`; will overwrite existing files
	**/
	public function writeResults( path:String ) {
		println( "Writing results" );
		var results = sim.state.results; // just a shortcut
		if ( results == null )
			throw "No results";
		var eout = writeEtt( ODResult, ODResult.ettFields(), path );
		for ( v in results )
			eout.write( v );
		eout.close();
	}



	// RESULT ANALYSIS ----------------------------------------------------------

	/**
		Analyze link with id `id`; `type` may be a comma separated list of
		"volumes", "ods", "usage", "save-usage" or "_" (for everything);
		requires results with saved paths and volumes (when applicable)
	**/
	public function analyze( id:Int, type:String ) {
		if ( sim.state.links == null )
			throw "No links";
		var link = sim.state.links.get( id );
		if ( link == null )
			throw "No link '"+id+"'";

		var azVol = false;
		var azOds = false;
		var azUsg = false;
		var svUsg = false;

		var types = readSet( type, true );
		if ( types == null )
			azVol = azOds = azUsg = svUsg = true;
		else for ( t in types ) {
			switch ( t.toLowerCase() ) {
			case "volumes", "volume", "vol":
				azVol = true;
			case "ods", "pairs", "od":
				azOds = true;
			case "usage":
				azUsg = true;
			case "save-usage", "save", "toll":
				svUsg = true;
			case "users":
				throw "No analysis type 'users'; did you mean 'usage' or 'ods'";
			case all:
				throw "No analysis type '"+all+"'";
			}
		}

		azUsg = azUsg || svUsg;

		var res = sim.state.results;
		if ( res == null )
			throw "No results";

		println( "Analyzing link '"+link.id+"'" );

		var resCnt = 0;
		var users = null; // array of OD::id

		if ( azUsg || azOds ) { // output O/D record ids
			users = [];
			for ( r in res ) {
				if ( r.path != null ) {
					if ( svUsg )
						r.escaped = true;
					resCnt++;
					if ( has( r.path, link.id ) ) {
						users.push( r.odId );
						if ( svUsg )
							r.escaped = false;
					}
				}
				else if ( svUsg )
					r.escaped = null;
			}
			users.sort( Reflect.compare );
			if ( azOds )
				println( "  * "+users.length+" O/D records using link: { "+users.join(", ")+" }" );
		}

		if ( azVol ) { // output volumes
			var vols = sim.state.volumes;
			if ( vols == null )
				throw "No volumes";
			var v = vols.exists( link.id ) ? vols.get( link.id ) : LinkVolume.make( 0, 0, 0, 0, 0 );
			println( "  * link volumes:");
			println( "        "+left(strnum(v.vehicles,2,0),9)+"  vehicles" );
			println( "        "+left(strnum(v.equivalentVehicles,2,0),9)+"  equivalent vehicles" );
			println( "        "+left(strnum(v.axis,2,0),9)+"  axis" );
			println( "        "+left(strnum(v.tolls,2,0),9)+"  toll multipliers" );
		}

		if ( azUsg ) { // output usage (prob) and error
			var n = resCnt;
			var p = users.length/resCnt;
			var exp = n*p;
			var s2 = n*p*( 1. - p );
			var s = Math.sqrt( s2 );
			println( "  * result analysis:" );
			println( "    "+left(n,5)+"  allocated O/D pairs" );
			println( "    "+left(users.length,5)+"  pairs using this link" );
			println( "    "+left(strnum(s,2,0),5)+"  standard deviation" );
			println( "    error(+/-):        NPQ    Wald   Agresti-Coull" );
			println( "        conf. 70%: "+strnum(pConf_NPQ(n,p,.30)*1e2,2,6)
			+"% "+strnum(pConf_Wald(n,p,.30)*1e2,2,6)
			+"% "+strnum(pConf_AgrestiCoull(n,p,.30)*1e2,2,14)+"%" );
			println( "        conf. 85%: "+strnum(pConf_NPQ(n,p,.15)*1e2,2,6)
			+"% "+strnum(pConf_Wald(n,p,.15)*1e2,2,6)
			+"% "+strnum(pConf_AgrestiCoull(n,p,.15)*1e2,2,14)+"%" );
			println( "        conf. 90%: "+strnum(pConf_NPQ(n,p,.10)*1e2,2,6)
			+"% "+strnum(pConf_Wald(n,p,.10)*1e2,2,6)
			+"% "+strnum(pConf_AgrestiCoull(n,p,.10)*1e2,2,14)+"%" );
			println( "        conf. 95%: "+strnum(pConf_NPQ(n,p,.05)*1e2,2,6)
			+"% "+strnum(pConf_Wald(n,p,.05)*1e2,2,6)
			+"% "+strnum(pConf_AgrestiCoull(n,p,.05)*1e2,2,14)+"%" );
		}

	}
	private function pConf_NPQ( sampleSize:Float, prob:Float, conf:Float ) {
		return zscore( .5*conf )*Math.sqrt( sampleSize*prob*( 1. - prob ) )/sampleSize;
	}
	private function pConf_Wald( sampleSize:Float, prob:Float, conf:Float ) {
		return zscore( .5*conf )*Math.sqrt( prob*( 1. - prob )/sampleSize );
	}
	private function pConf_AgrestiCoull( sampleSize:Float, prob:Float, conf:Float ) {
		var _prob = ( sampleSize*prob + .5*zscore( .5*conf ) )
		           /(   sampleSize   + zscore( .5*conf )*zscore( .5*conf ) );
		return zscore( conf*.5 )*Math.sqrt( _prob*( 1. - _prob )/sampleSize );
	}
	private function zscore( conf:Float ) {
		return stat.ZScore.forProbGreaterThan( 1.-conf );
	}



	// COMMAND HISTORY ----------------------------------------------------------

	/**
		Reset the current state of the simulator
	**/
	public function reset() {
		print( "Reseting the current state" );
		sim.reset();
		println( "\rReseting the current state... Done" );
	}

	/**
		Save the current command log (from the last reset) to `path`
	**/
	public function save( path:String ) {
		print( "Saving the current command log" );
		if ( !reading ) {
			var fout = writeFile( path, false );
			fout.writeString( sim.log.join( sim.newline )+sim.newline );
			fout.close();
		}
		println( "\rSaving the current command log... Done" );
	}

	/**
		Execute from a command log in `path`
	**/
	public function restore( path:String ) {
		if ( !reading ) {
			printHL( "-" );
			printHL( "-" );
		}
		println( "Reading commands in '"+path+"'" );
		if ( !reading )
			println( "" );

		var finp = readFile( path, false );
		var inp = new format.csv.Reader( finp, sim.newline, " ", "'" );
		var eof = false;
		while ( !eof ) {
			try {
				var r = inp.readRecord();
				if ( r.length != 0 ) {
					println( ":: "+r.join( " " ) );
					sim.run( r, true, true, false );
				}
			}
			catch ( e:haxe.io.Eof ) {
				eof = true;
			}
		}
		inp.close();
		
		if ( !reading )
			println( "" );
		println( "Reading commands in '"+path+"'... Done" );
		if ( !reading ) {
			printHL( "-" );
			printHL( "-" );
		}
	}

	/**
		Show the current command log
	**/
	public function showLog() {
		println( "Showing the current log" );
		printHL( "-" );
		println( "    :: "+sim.log.join( "\n    :: " ) );
	}



	// TUNING -------------------------------------------------------------------

	/**
		[TUNING] Set heap arity for the internal priority queue used on Dijkstra and A*
	**/
	public function setHeapArity( no:Int ) {
		sim.state.heapArity = no;
		if ( sim.state.digraph != null )
			sim.state.digraph.heapArity = sim.state.heapArity;
		println( "Heap (Dijkstra/A* priority queue) arity set to "+no );
	}

	/**
		[TUNING] Set heap initial reserve for the internal priority queue used on Dijkstra
		and A*
	**/
	public function setHeapReserve( no:Int ) {
		sim.state.heapReserve = no;
		if ( sim.state.digraph != null )
			sim.state.digraph.heapReserve = sim.state.heapReserve;
		println( "Heap (Dijkstra/A* priority queue) initial reserve set to "+no );
	}



	// ADVANCED -----------------------------------------------------------------

	/**
		[ADVANCED] Set the newline sequence for all file output
	**/
	public function setNewline( sequence:String ) {
		switch ( sequence ) {
		case "NL": sim.state.newline = "\n"; sim.prepareForInput();
		case "CRNL": sim.state.newline = "\r\n"; sim.prepareForInput();
		case "NLCR": sim.state.newline = "\n\r"; sim.prepareForInput();
		case all: throw "Unrecognized newline sequence: "+all;
		}
	}

	/**
		[ADVANCED] Peek at the newline sequence for all file output
	**/
	public function showNewline() {
		switch ( sim.state.newline ) {
		case "\n": println( "Current newline sequence is NL" );
		case "\r\n": println( "Current newline sequence is CRNL" );
		case "\n\r": println( "Current newline sequence is NLCR" );
		case all: throw "Something went wrong";
		}
	}

	/**
		[ADVANCED] Set console screen width
	**/
	public function setScreen( columns:Int ) {
		if ( columns < 50 )
			throw "Cannot set the number of columns on the screen to a value bellow 50";
		sim.screenSize = columns;
	}

	/**
		[ADVANCED] Force network and graph assembly; this is
		automaticallly called from --run
	**/
	public function forceAssemble() assemble( true );
	private function assemble( ?force=false ) {
		if ( force ) {
			println( "Forcing online network and graph assembly" );
			printHL( "-" );
		}
		if ( sim.state.network == null || force ) {
			println( "Assembling the network" );
			sim.state.digraph = null;
			var nk = sim.state.network = new OnlineNetwork( sim );
		}
		if ( sim.state.digraph == null || force ) {
			println( "Assembling the (directed) graph" );
			var dg = sim.state.digraph = new OnlineDigraph( sim );
		}
	}

	/**
		[ADVANCED] Run the unit tests; these are relevant at the moment, since
		they only test the previous graph implementation
	**/
	public function unitTests() {
		println( "Running the unit tests" );
		printHL( "-" );
		var app = new test.unit.UnitTests();
		app.run();
	}

	#if cpp
	/**
		[ADVANCED] Enable the HXCPP internal C++ profiler
	**/
	public function enableProfiling( basePath:String ) {
		sim.profiling = basePath;
	}
	#end

	#if cpp
	/**
		[ADVANCED] Disable the HXCPP internal C++ profiler
	**/
	public function disableProfiling() {
		sim.profiling = null;
	}
	#end

	#if false
	/**
		[DO NOT USE] Space for testing
	**/
	@:access( graph.linkList.Digraph )
	public function something() {
		println( "Running something" );
		printHL( "-" );
		var v = 10;
		var a = 20;
		for ( n in 1...#if neko 4 #else 5 #end ) {
			v *= 10;
			a *= 10;
			trace( '====== #v=$v, #a=$a ======' );
			var d = new graph.linkList.Digraph();
			trace( 'initialized a new digraph' );
			var t0 = haxe.Timer.stamp();
			for ( i in 0...v )
				d.addVertex( new def.Node( i, i, i ) );
			var tel = haxe.Timer.stamp() - t0;
			trace( 'added $v vertices in $tel' );
			var auto = new def.VehicleClass( 0, 1, 1, 1, "Auto" );
			var speed = new def.Speed();
			speed.set( auto, 60 );
			t0 = haxe.Timer.stamp();
			for ( i in 0...a ) {
				var s = d.vs.get( Std.random( v ) );
				var t = s;
				while ( s == t )
					t = d.vs.get( Std.random( v ) );
				d.addArc( new def.Link( i, s.node, t.node, Math.random()*10, speed, 0. ) );
			}
			tel = haxe.Timer.stamp() - t0;
			trace( 'added $a arcs in $tel' );
			t0 = haxe.Timer.stamp();
			var ucost = new def.UserCostModel( 1., 0., 0. );
			for ( i in 0...10 ) {
				var s = d.vs.get( i );
				d.simpleSSSPT( s.node, 0., auto, ucost );
			}
			tel = haxe.Timer.stamp() - t0;
			trace( 'ran 10 single source shortest paths in $tel' );
			trace( '... ${tel/10} per source, on average' );
			trace( "" );
			printHL( "-" );
		}
	}
	#end

	/**
		[ADVANCED] Dump any table in its corresponding ETT; only works if the
		table exists and has at least one record; will overwrite existing files
	**/
	public function dumpEtt( table:String, path:String ) {
		println( "Attempting to dump table "+table+" in '"+path+"'" );
		var table:{ iterator:Void->Iterator<Dynamic> } = Reflect.field( sim.state, table );
		if ( table == null )
			throw "No table";
		if ( !table.iterator().hasNext() )
			throw "Cannot figure out the type of an EMPTY table";
		var cl:Dynamic = Type.getClass( table.iterator().next() );
		var eout = writeEtt( cl, cl.ettFields(), path );
		for ( r in table )
			eout.write( r );
		eout.close();
	}

	/**
		[ADVANCED] Query any table of objects, optionally specifying another
		suitable alias table
	**/
	public function justQuery( table:String, type:String, expression:String, ?aliases:String ) {
		var idName = switch ( table ) {
		case "volumes": "linkId";
		case "results": "odId";
		case "speeds": "key";
		case all: "id";
		}
		println( "Attempting to query table "+table+" with '"+expression+"'" );
		var index:Map<Int,Dynamic> = Reflect.field( sim.state, table );
		if ( table == null )
			throw "No table";
		var alias:Map<String,Iterable<Int>> = aliases != null ? Reflect.field( sim.state, aliases ) : null;
		var q = Query.prepare( expression, idName );
		switch ( type.toLowerCase() ) {
		case "show", "list":
			for ( v in q.execute( index, alias ) )
				println( Std.string( v ) );
		case "head":
			var cnt = 0;
			for ( v in q.execute( index, alias ) )
				if ( cnt++ < 20 )
					println( Std.string( v ) );
		case "count":
			println( "Counted "+count( q.execute( index, alias ) )+" records" );
		}

	}

	/**
		[HACK] Windows hack for problems with newlines
	**/
	public function windows() {
		sim.newline = "\r\n";
		sim.prepareForInput();
	}


	// OTHERS -------------------------------------------------------------------

	/**
		Show simulator version
	**/
	public function version() {
		println( "RodoTollSim version "+Simulator.VERSION );
	}

	/**
		Show simulator version and platform information
	**/
	public function fullVersion() {
		println( "RodoTollSim version "+Simulator.VERSION+" ("+Simulator.PLATFORM
		+" on "+Sys.systemName()+")" );
	}

	/**
		Print usage
	**/
	public function help() {
		println( "Usage:" );
		printHL( "-" );
		print( mcli.Dispatch.showUsageOf( this.getArguments(), sim.screenSize ) );
	}

	/**
		Quit
	**/
	public function quit() {
		if ( sim.online ) {
			println( "Exiting gracefully" );
			printHL( "=" );
		}
		Sys.exit( 0 );
	}



	// HELPERS ------------------------------------------------------------------

	private function queryOd( original:Iterable<OD>, type:String, clause:String
	, ?originalFilter:Array<String> ):Null<Iterable<OD>> {
		var c = readSet( clause );
		if ( c == null )
			return null; // all selected
		var activeOds = original;
		switch ( type ) {
		case "id":
			var f = c.map( parseInt );
			if ( originalFilter != null ) originalFilter.push( "`id` in ("+f.join(",")+")" );
			activeOds = filter( activeOds, function (od) return has(f,od.id) );
		case "lot":
			var f = c.map( parseInt );
			if ( originalFilter != null ) originalFilter.push( "`lot` in ("+f.join(",")+")" );
			activeOds = filter( activeOds, function (od) return has(f,od.lot) );
		case "section", "point", "pt":
			var f = c.map( parseInt );
			if ( originalFilter != null ) originalFilter.push( "`section` in ("+f.join(",")+")" );
			activeOds = filter( activeOds, function (od) return has(f,od.section) );
		case "direction", "dir":
			var f = c.map( parseInt );
			if ( originalFilter != null ) originalFilter.push( "`direction` in ("+f.join(",")+")" );
			activeOds = filter( activeOds, function (od) return has(f,od.direction) );
		case "vehicle", "vehicleId", "veh":
			var f = c.map( parseInt );
			if ( originalFilter != null ) originalFilter.push( "`vehicleId` in ("+f.join(",")+")" );
			activeOds = filter( activeOds, function (od) return has(f,od.vehicleId) );
		case "cargo", "product", "prod":
			if ( originalFilter != null ) originalFilter.push( "`cargo` in ('"+c.join("','")+"'')" );
			activeOds = filter( activeOds, function (od) return has(c,od.cargo) );
		case all: throw "Unknown filter type '"+type+"'";
		}
		return activeOds;
	}

	private function geojsonLink( link:Link ):String {
		var linkProp = link.jsonBody();
		var geom = getShape( link ).geojsonGeometry();
		return '{"id":${link.id},"type":"Feature","geometry":$geom,"properties":{$linkProp}}';
	}

	private function geojsonVolume( volume:LinkVolume ):String {
		var link = sim.state.links.get( volume.linkId );
		var linkProp = link.jsonBody();
		var linkVolume = volume.jsonBody();
		var geom = getShape( link ).geojsonGeometry();
		return '{"id":${link.id},"type":"Feature","geometry":$geom,"properties":{$linkProp,$linkVolume}}';
	}

	private function getShape( link:Link):LinkShape {
		var shapes = sim.state.shapes;
		if ( shapes == null )
			sim.state.shapes = shapes = new Map();
		var shp = shapes.get( link.id );
		if ( shp == null )
			shp = autoLinkShape( link );
		return shp;
	}

	private function autoLinkShape( link:Link ):LinkShape {
		var nodes = sim.state.nodes;
		if ( nodes == null ) throw "No nodes";
		var pts = [ nodes.get( link.startNodeId ).point, nodes.get( link.finishNodeId ).point ];
		var shp = LinkShape.make( link.id, new format.ett.Geometry.LineString( pts ) );
		sim.state.shapes.set( link.id, shp );
		return shp;
	}

	private function readEtt( inputPath:String ):ETTReader {
		return new ETTReader( readFile( inputPath, true ) );
	}

	private function writeEtt( cl:Class<Dynamic>, fields:Array<ETTField>, outputPath:String ):ETTWriter {
		var fout = writeFile( outputPath, true );
		var finfo = new format.ett.Data.FileInfo( sim.newline, ETTEncoding.UTF8, "\t", "\""
		, Type.getClassName( cl ), fields );
		var w = new ETTWriter( finfo );
		w.prepare( fout );
		return w;
	}

	private function readFile( inputPath:String, binary:Bool ):FileInput {
		if ( !sys.FileSystem.exists( inputPath ) )
			throw "File '"+inputPath+"' does not exist";
		if ( sys.FileSystem.isDirectory( inputPath ) )
			throw "Expected a file but found a folder: '"+inputPath+"'";
		return sys.io.File.read( inputPath, binary );
	}

	private function writeFile( outputPath:String, binary:Bool ):FileOutput {
		if ( sys.FileSystem.exists( outputPath ) )
			if ( sys.FileSystem.isDirectory( outputPath ) )
				throw "Cannot overwrite a folder with a file: '"+outputPath+"'";
			else
			 	println( "File '"+outputPath+"' overwritten" );
		return sys.io.File.write( outputPath, binary );
	}

	private function right( data:Dynamic, len:Int, ?pad=" " ):String {
		return StringTools.lpad( string( data ), pad, len );
	}

	private function left( data:Dynamic, len:Int, ?pad=" " ):String {
		return StringTools.rpad( string( data ), pad, len );
	}

	private function strnum( v:Float, p:Int, len:Int ):String {
		return printDecimal( v, len, p );
	}

	private function readInt( s:String, ?nullable=true ):Null<Int> {
		return switch ( s.toLowerCase() ) {
		case "", "_", "*", "a", "all": if ( nullable ) null; else throw "Invalid Int "+s;
		case all: parseInt( s );
		};
	}

	private function readBool( s:Null<String>, ?nullable=true ):Null<Bool> {
		if ( s == null )
			if ( nullable ) return true;
			else throw "Boll cannot be null";
		else
			return switch ( s.toLowerCase() ) {
			case "", "_", "*", "a", "all": if ( nullable ) null; else throw "Invalid Bool "+s;
			case "false", "no", "n", "0": false;
			case "true", "yes", "y", "1": true;
			case all: throw "Invalid Bool "+s;
			};
	}

	private static function readSet( s:String, ?nullable=true ):Null<Array<String>> {
		return switch ( s.toLowerCase() ) {
		case "", "_", "*": null; if ( nullable ) null; else throw "Invalid String "+s;
		case all: s.split( "," );
		};
	}

}
