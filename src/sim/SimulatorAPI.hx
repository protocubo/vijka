package sim;

import elebeta.ett.rodoTollSim.*;
import format.ett.Data.Encoding in ETTEncoding;
import format.ett.Data.Field in ETTField;
import format.ett.Reader;
import format.ett.Writer;
import haxe.io.Eof;
import sys.io.FileInput;
import sys.io.FileOutput;

import Std.parseFloat;
import Std.parseInt;
import Std.string;
import Lambda.list;
import Lambda.array;
import Lambda.filter;
import Lambda.has;
import Lambda.count;

import sim.col.*;
import sim.OnlineNetwork;
import sim.Simulator;
import sim.SimulatorState;

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
		Read nodes (reentrant)
	**/
	public function readNodes( inputPath:String ) {
		if ( sim.state.nodes == null ) {
			println( "Reading nodes" );
			sim.state.nodes = new Map();
		}
		else {
			println( "Reading additional nodes" );
			println( "Existing nodes may have been changed, consider verifying link shapes" );
		}
		var nodes = sim.state.nodes; // just a shortcut
		var einp = readEtt( inputPath );
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
		Read link types (reentrant)
	**/
	public function readLinkTypes( inputPath:String ) {
		if ( sim.state.linkTypes == null ) {
			println( "Reading link types" );
			sim.state.linkTypes = new Map();
		}
		else {
			println( "Reading additional link types" );
		}
		var linkTypes = sim.state.linkTypes; // just a shortcut
		var einp = readEtt( inputPath );
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
	public function showLinkTypes() {
		println( "Known types:" );
		println( right("id",6)+"  |  name" );
		printHL( "-" );
		for ( type in sim.state.linkTypes )
			println( right(type.id,6)+"  |  "+type.name );
	}

	/**
		Count link types
	**/
	public function countLinkTypes() {
		var cnt = sim.state.linkTypes != null ? count( sim.state.linkTypes ) : 0;
		println( "Counted "+cnt+" link types" );
	}



	// LINK I/O -----------------------------------------------------------------

	/**
		Read links (reentrant); requires nodes and link types; link extensions in km
	**/
	public function readLinks( inputPath:String ) {
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
		var einp = readEtt( inputPath );
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



	// VEHICLE I/O --------------------------------------------------------------

	/**
		Read vehicles (reentrant)
	**/
	public function readVehicles( inputPath:String ) {
		if ( sim.state.vehicles == null ) {
			println( "Reading vehicles" );
			sim.state.vehicles = new Map();
		}
		else {
			println( "Reading additional vehicles" );
		}
		var vehicles = sim.state.vehicles; // just a shortcut
		var einp = readEtt( inputPath );
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
		Read link type speeds (reentrant); speeds in km/h
	**/
	public function readSpeeds( inputPath:String ) {
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
		var einp = readEtt( inputPath );
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
		Show speeds for links with [typeId]  and [vehicleId]; for all types and/or
		vehicles use '*'
	**/
	public function showSpeeds( typeId:String, vehicleId:String ) {
		var t:Null<Int> = readInt( typeId );
		var v:Null<Int> = readInt( vehicleId );
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
		Read od data (reentrant)
	**/
	public function readOdData( inputPath:String ) {
		if ( sim.state.ods == null ) {
			println( "Reading od data" );
			sim.state.ods = new Map();
		}
		else {
			println( "Reading additional od data" );
			sim.state.activeOds = null;
			sim.state.activeOdFilter = null;
		}
		var vehicles = sim.state.vehicles; // just a shortcut
		var ods = sim.state.ods; // just a shortcut
		if ( vehicles == null ) throw "No vehicles";
		var einp = readEtt( inputPath );
		while ( true ) {
			var od = try { einp.fastReadRecord( OD.makeEmpty() ); }
			         catch ( e:Eof ) { null; };
			if ( od == null ) break;
			if ( !vehicles.exists( od.vehicleId ) )
			if ( !vehicles.exists( od.vehicleId ) )
				throw "Missing vehicle "+od.vehicleId;
			ods.set( od.id, od );
		}
		einp.close();
	}

	/**
		Count ods
	**/
	public function countOdData() {
		var cnt = sim.state.ods != null ? count( sim.state.ods ) : 0;
		println( "Counted "+cnt+" od records" );
	}



	// RUNNING ------------------------------------------------------------------

	/**
		Set a different algorithm; the avaliable ones are Dijkstra, A* and
		Bellmand-Ford
	**/
	public function setAlgorithm( name:String ) {
		var algo = switch ( name.toLowerCase() ) {
		case "dijkstra", "ijk":
			ADijkstra;
		case "a*", "astar", "a-star", "star":
			AAStar;
		case "bellman-ford", "bford", "bell":
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
		Show the current enabled algorithm
	**/
	public function showAlgorithm() {
		println( "The current algithm is: "+algoName( sim.state.algorithm ) );
	}
	private function algoName( a:Algorithm ) {
		return switch ( a ) {
		case ADijkstra: "Dijkstra";
		case AAStar: "A*";
		case ABellmanFord: "Bellman-Ford";
		};
	}

	/**
		Filter O/D data (reentrant); type may be `id`, `lot`, `section`, `direction`,
		`vehicleId` and `cargo`
	**/
	public function filterOd( type:String, clause:String ) {
		var c = readSet( clause );
		if ( c == null )
			return; // all selected
		var ods = sim.state.ods;
		if ( ods == null ) throw "No O/D data";
		var activeOds = list( sim.state.activeOds != null ? sim.state.activeOds : sim.state.ods );
		var activeOdFilter = sim.state.activeOdFilter; if ( activeOdFilter == null ) activeOdFilter = [];
		switch ( type ) {
		case "id":
			var f = c.map( parseInt );
			var exp = "`id` in ("+f.join(",")+")";
			activeOdFilter.push( exp );
			println( "Filtering OD data with clause: "+exp );
			activeOds = filter( activeOds, function (od) return has(f,od.id) );
		case "lot":
			var f = c.map( parseInt );
			var exp = "`lot` in ("+f.join(",")+")";
			activeOdFilter.push( exp );
			println( "Filtering OD data with clause: "+exp );
			activeOds = filter( activeOds, function (od) return has(f,od.lot) );
		case "section", "point", "pt":
			var f = c.map( parseInt );
			var exp = "`section` in ("+f.join(",")+")";
			activeOdFilter.push( exp );
			println( "Filtering OD data with clause: "+exp );
			activeOds = filter( activeOds, function (od) return has(f,od.section) );
		case "direction", "dir":
			var f = c.map( parseInt );
			var exp = "`direction` in ("+f.join(",")+")";
			activeOdFilter.push( exp );
			println( "Filtering OD data with clause: "+exp );
			activeOds = filter( activeOds, function (od) return has(f,od.direction) );
		case "vehicle", "vehicleId", "veh":
			var f = c.map( parseInt );
			var exp = "`vehicleId` in ("+f.join(",")+")";
			activeOdFilter.push( exp );
			println( "Filtering OD data with clause: "+exp );
			activeOds = filter( activeOds, function (od) return has(f,od.vehicleId) );
		case "cargo", "product", "prod":
			var exp = "`cargo` in ('"+c.join("','")+"'')";
			activeOdFilter.push( exp );
			println( "Filtering OD data with clause: "+exp );
			activeOds = filter( activeOds, function (od) return has(c,od.cargo) );
		case all: throw "Unknown filter type '"+type+"'";
		}
		sim.state.activeOds = array( activeOds );
		sim.state.activeOdFilter = activeOdFilter;
		println( "Current selected records: "+activeOds.length );
	}

	/**
		Show O/D query expression
	**/
	public function showOdFilter() {
		if ( sim.state.activeOdFilter == null )
			println( "No O/D filter at the moment... All available data selected" );
		else
			println( "Selected O/D records: where "+sim.state.activeOdFilter.join("\n\t&& ") );
	}

	/**
		Clear all O/D filters
	**/
	public function clearOdFilter() {
		sim.state.activeOds = null;
		sim.state.activeOdFilter = null;
	}

	public function run( volumes:String, path:String ) {
		var ods:Iterable<OD> = sim.state.activeOds != null ? sim.state.activeOds : sim.state.ods;
		if ( ods == null ) throw "No O/D data";
		var odCnt = count( ods );
		if ( odCnt == 0 ) {
			println( "No O/D records... Try to remove the filter with --clear-od-filter" );
			return;
		}
		var saveVols = readBool( volumes, false );
		var savePath = readBool( path, false );
		assemble();
		if ( sim.state.results == null ) sim.state.results = new Map();
		if ( saveVols && sim.state.volumes == null ) sim.state.volumes = new Map();
		var G = sim.state.digraph;
		println( "Running "+odCnt+" records" );
		showAlgorithm();
		printHL( "-" );
		var lt = haxe.Timer.stamp();
		var i = 0;
		print( "\r("+i+"/"+odCnt+")" );
		for ( od in ods ) {
			G.run( od, saveVols, savePath );
			i++;
			if ( haxe.Timer.stamp() - lt > .2 ) {
				lt = haxe.Timer.stamp();
				print( "\r("+i+"/"+odCnt+") on id "+left(od.id,9) );
			}
		}
		println( "\r("+i+"/"+odCnt+") "+left("done...",9+6) );
	}

	/**
		Clear all result data from state
	**/
	public function clearResults() {
		sim.state.clearResults();
	}


	// VOLUME I/O ---------------------------------------------------------------

	/**
		Write volumes to ETT
	**/
	public function writeVolumes( outputPath:String ) {
		println( "Writing volumes" );
		var volumes = sim.state.volumes; // just a shortcut
		if ( volumes == null )
			throw "No volumes";
		var eout = writeEtt( LinkVolume, LinkVolume.ettFields(), outputPath );
		for ( v in volumes )
			eout.write( v );
		eout.close();
	}

	/**
		Write volumes to GeoJSON, using available link shape data
	**/
	public function geojsonVolumes( outputPath:String ) {
		println( "Mapping volumes in GeoJSON" );
		var volumes = sim.state.volumes; // just a shortcut
		if ( volumes == null ) throw "No volumes";
		var fout = writeFile( outputPath, false );
		fout.writeString( '{"type":"FeatureCollection","features":[\n' );
		var first = true;
		for ( v in volumes ) {
			if ( first ) first = false; else fout.writeString( ",\n" );
			fout.writeString( geojsonVolume( v ) );
		}
		fout.writeString( "\n] }\n" );
		fout.close();
	}


	// RESULTS I/O --------------------------------------------------------------

	/**
		Write results to ETT
	**/
	public function writeResults( outputPath:String ) {
		println( "Writing results" );
		var results = sim.state.results; // just a shortcut
		if ( results == null )
			throw "No results";
		var eout = writeEtt( ODResult, ODResult.ettFields(), outputPath );
		for ( v in results )
			eout.write( v );
		eout.close();
	}


	// RESULT ANALYSIS ----------------------------------------------------------

	// TODO


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
		Save the current command log (from the last reset) to [path]
	**/
	public function save( path:String ) {
		print( "Saving the current command log" );
		if ( !reading ) {
			var fout = writeFile( path, false );
			fout.writeString( sim.log.join( "\n" )+"\n" );
			fout.close();
		}
		println( "\rSaving the current command log... Done" );
	}

	/**
		Read a command log from [path]
	**/
	public function read( path:String ) {
		if ( !reading ) {
			printHL( "-" );
			printHL( "-" );
		}
		println( "Reading commands in '"+path+"'" );
		if ( !reading )
			println( "" );

		var finp = sys.io.File.read( path, false );
		var inp = new format.csv.Reader( finp, "\n", " ", "'" );
		var eof = false;
		while ( !eof ) {
			try {
				var r = inp.readRecord();
				if ( r.length != 0 ) {
					println( ":: "+r.join( " " ) );
					sim.run( r, true );
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

	public function showLog() {
		println( "Showing the current log" );
		printHL( "-" );
		println( "\t// "+sim.log.join( "\n\t// " ) );
	}



	// ADVANCED -----------------------------------------------------------------

	/**
		[advanced] Force network and graph assembly; this is
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
		[advanced] Run the unit tests.
	**/
	public function unitTests() {
		println( "Running the unit tests" );
		printHL( "-" );
		var app = new test.unit.UnitTests();
		app.run();
	}

	/**
		[advanced] Enable the code profiler; only available on C++ versions,
		NOOP elsewhere.
	**/
	public function enableProfiling( basePath:String ) {
		sim.profiling = basePath;
	}

	/**
		[advanced] Disable the code profiler; only available on C++ versions,
		NOOP elsewhere.
	**/
	public function disableProfiling() {
		sim.profiling = null;
	}

	/**
		[undocumented] Space for testing
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

	/**
		[advanced] Dump ETT
	**/
	public function dumpEtt( table:String, outputPath:String ) {
		println( "Attempting to dump table "+table+" in '"+outputPath+"'" );
		var table:{ iterator:Void->Iterator<Dynamic> } = Reflect.field( sim.state, table );
		if ( table == null )
			throw "No table";
		if ( !table.iterator().hasNext() )
			throw "Cannot figure out the type of an EMPTY table";
		var cl:Dynamic = Type.getClass( table.iterator().next() );
		var eout = writeEtt( cl, cl.ettFields(), outputPath );
		for ( r in table )
			eout.write( r );
		eout.close();
	}

	/**
		[undocumented] Windows hack for problems with stdin
	**/
	@:access( sim.Simulator )
	public function windows() {
		sim.inp = new format.csv.Reader( Simulator.stdin, "\r\n", " ", "'" );
	}


	// OTHERS -------------------------------------------------------------------

	/**
		Show simulator version.
	**/
	public function version() {
		println( "RodoTollSim version "+Simulator.VERSION );
	}

	/**
		Show simulator version and platform information.
	**/
	public function fullVersion() {
		println( "RodoTollSim version "+Simulator.VERSION+" ("+Simulator.PLATFORM+")" );
	}

	/**
		Print usage.
	**/
	public function help() {
		println( "Usage:" );
		printHL( "-" );
		print( this.showUsage() );
	}

	/**
		Quit.
	**/
	public function quit() {
		Sys.exit( 0 );
	}



	// HELPERS ------------------------------------------------------------------

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

	private static function readEtt( inputPath:String ):ETTReader {
		return new ETTReader( readFile( inputPath, true ) );
	}

	private static function writeEtt( cl:Class<Dynamic>, fields:Array<ETTField>, outputPath:String ):ETTWriter {
		var fout = writeFile( outputPath, true );
		var finfo = new format.ett.Data.FileInfo( "\n", ETTEncoding.UTF8, "\t", "\""
		, Type.getClassName( cl ), fields );
		var w = new ETTWriter( finfo );
		w.prepare( fout );
		return w;
	}

	private static function readFile( inputPath:String, binary:Bool ):FileInput {
		if ( !sys.FileSystem.exists( inputPath ) )
			throw "File '"+inputPath+"' does not exist";
		if ( sys.FileSystem.isDirectory( inputPath ) )
			throw "Expected a file but found a folder: '"+inputPath+"'";
		return sys.io.File.read( inputPath, binary );
	}

	private static function writeFile( outputPath:String, binary:Bool ):FileOutput {
		if ( sys.FileSystem.exists( outputPath ) )
			if ( sys.FileSystem.isDirectory( outputPath ) )
				throw "Cannot overwrite a folder with a file: '"+outputPath+"'";
			else
			 	println( "File '"+outputPath+"' overwritten" );
		return sys.io.File.write( outputPath, binary );
	}

	private static function right( data:Dynamic, len:Int, ?pad=" " ):String {
		return StringTools.lpad( string( data ), pad, len );
	}

	private static function left( data:Dynamic, len:Int, ?pad=" " ):String {
		return StringTools.rpad( string( data ), pad, len );
	}

	private static function readInt( s:String, ?nullable=true ):Null<Int> {
		return switch ( s.toLowerCase() ) {
		case "", "_", "*", "a", "all": if ( nullable ) null; else throw "Invalid Int "+s;
		case all: parseInt( s );
		};
	}

	private static function readBool( s:String, ?nullable=true ):Null<Bool> {
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
