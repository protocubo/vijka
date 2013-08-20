package sim;

import elebeta.ett.rodoTollSim.*;
import format.ett.Data.Field in ETTField;
import format.ett.Data.Encoding in ETTEncoding;
import format.ett.Reader;
import format.ett.Writer;
import haxe.io.Eof;
import sim.OnlineNetwork;
import sys.io.FileInput;
import sys.io.FileOutput;

import Std.parseFloat;
import Std.parseInt;
import Std.string;

import sim.col.*;
import sim.Simulator;

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
		printHL( "-" );
		var nodes = sim.state.nodes; // just a shortcut
		var einp = readEtt( inputPath );
		sim.state.invalidate();
		while ( true ) {
			var node = try { einp.fastReadRecord( Node.makeEmpty() ); }
			           catch ( e:Eof ) { null; };
			if ( node == null ) break;
			nodes.set( node.id, node );
		}
	}

	/**
		Count nodes
	**/
	public function countNodes() {
		var cnt = sim.state.nodes != null ? Lambda.count( sim.state.nodes ) : 0;
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
		printHL( "-" );
		var linkTypes = sim.state.linkTypes; // just a shortcut
		var einp = readEtt( inputPath );
		while ( true ) {
			var type = try { einp.fastReadRecord( LinkType.makeEmpty() ); }
			           catch ( e:Eof ) { null; };
			if ( type == null ) break;
			linkTypes.set( type.id, type );
		}
	}

	/**
		Show link types
	**/
	public function showLinkTypes() {
		println( "Known types:" );
		printHL( "-" );
		for ( type in sim.state.linkTypes )
			println( right(type.id,6)+": "+type.name );
		printHL( "-" );
	}

	/**
		Count link types
	**/
	public function countLinkTypes() {
		var cnt = sim.state.linkTypes != null ? Lambda.count( sim.state.linkTypes ) : 0;
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
		printHL( "-" );
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
	}

	/**
		Count links
	**/
	public function countLinks() {
		var cnt = sim.state.links != null ? Lambda.count( sim.state.links ) : 0;
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
		printHL( "-" );
		var vehicles = sim.state.vehicles; // just a shortcut
		var einp = readEtt( inputPath );
		sim.state.invalidate(); // this might (and should) not be necessary in the future
		while ( true ) {
			var type = try { einp.fastReadRecord( Vehicle.makeEmpty() ); }
			           catch ( e:Eof ) { null; };
			if ( type == null ) break;
			vehicles.set( type.id, type );
		}
	}

	/**
		Show vehicles
	**/
	public function showVehicles() {
		println( "Known types:" );
		printHL( "-" );
		for ( type in sim.state.vehicles )
			println( right(type.id,6)+": "+type.name );
		printHL( "-" );
	}

	/**
		Count vehicles
	**/
	public function countVehicles() {
		var cnt = sim.state.vehicles != null ? Lambda.count( sim.state.vehicles ) : 0;
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
		printHL( "-" );
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
	}

	/**
		Show speeds for links with [typeId]  and [vehicleId]; for all types and/or
		vehicles use '*'
	**/
	public function showSpeeds( typeId:String, vehicleId:String ) {
		var t:Null<Int> = typeId != "*" ? parseInt( typeId ) : null;
		var v:Null<Int> = vehicleId != "*" ? parseInt( vehicleId ) : null;
		print( "Link speeds for " );
		print( t != null ? " typeId="+t+" " : "all link types " );
		println( v != null ? " vehicleId="+v+" " : "all vehicles:" );
		printHL( "-" );
		// TODO get typeId,vehicleId from the other collections and show missing values
		if ( sim.state.speeds == null )
			throw "No speeds";
		var speeds = [ for ( s in sim.state.speeds ) s ];
		speeds.sort( function (a,b) return 2*Reflect.compare(a.typeId,b.typeId)+Reflect.compare(a.vehicleId,b.vehicleId) );
		for ( speed in speeds )
			if ( ( t == null || speed.typeId == t )
			&& ( v == null || speed.vehicleId == v ) )
				println( right(speed.typeId,6)+", "+right(speed.vehicleId,6)+": "+speed.speed+" km/h" );
		printHL( "-" );
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
		}
		printHL( "-" );
		var vehicles = sim.state.vehicles; // just a shortcut
		var ods = sim.state.ods; // just a shortcut
		if ( vehicles == null ) throw "No vehicles";
		var einp = readEtt( inputPath );
		sim.state.invalidate();
		while ( true ) {
			var od = try { einp.fastReadRecord( OD.makeEmpty() ); }
			         catch ( e:Eof ) { null; };
			if ( od == null ) break;
			if ( !vehicles.exists( od.vehicleId ) )
			if ( !vehicles.exists( od.vehicleId ) )
				throw "Missing vehicle "+od.vehicleId;
			ods.set( od.id, od );
		}
	}

	/**
		Count ods
	**/
	public function countOdData() {
		var cnt = sim.state.ods != null ? Lambda.count( sim.state.ods ) : 0;
		println( "Counted "+cnt+" od records" );
	}



	// // VOLUME I/O -----------------------------------------------------------------

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
			var fout = sys.io.File.write( path, false );
			fout.writeString( sim.log.join( "\n" )+"\n" );
			fout.close();
		}
		println( "\rSaving the current command log... Done" );
	}

	/**
		Read a command log from [path]
	**/
	public function read( path:String ) {
		println( "Reading commands in '"+path+"'" );
		printHL( "=" );
		printHL( "#" );

		var finp = sys.io.File.read( path, false );
		var inp = new format.csv.Reader( finp, "\n", " ", "'" );
		var eof = false;
		while ( !eof ) {
			try {
				var r = inp.readRecord();
				println( ">> "+r.join( " " ) );
				sim.run( r, true );
			}
			catch ( e:haxe.io.Eof ) {
				eof = true;
			}
		}
		inp.close();
		
		println( "Reading commands in '"+path+"'... Done" );
		printHL( "#" );
		printHL( "=" );
	}

	public function showLog() {
		println( "Showing the current log" );
		printHL( "-" );
		println( "\t// "+sim.log.join( "\n\t// " ) );
		printHL( "-" );
	}



	// ADVANCED -----------------------------------------------------------------

	/**
		Assemble; creates the online network and graph; this is
		automaticallly called from --run
	**/
	public function assemble( ?force=true ) {
		if ( force ) {
			println( "Forcing online network and graph assembly" );
			printHL( "-" );
		}
		if ( sim.state.network == null || force ) {
			sim.state.digraph = null;
			var nk = sim.state.network = new OnlineNetwork( sim );
		}
		if ( sim.state.digraph == null || force ) {
			var dg = sim.state.digraph = new OnlineDigraph( sim );
		}
		if ( force ) {
			printHL( "-" );
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
		printHL( "-" );
	}

	/**
		[advanced] Enable the code profiler.
		Only available on C++ versions; NOOP elsewhere.
	**/
	public function enableProfiling( basePath:String ) {
		sim.profiling = basePath;
	}

	/**
		[advanced] Disable the code profiler.
		Only available on C++ versions; NOOP elsewhere.
	**/
	public function disableProfiling() {
		sim.profiling = null;
	}

	/**
		[undocumented] Space for testing.
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
			var auto = new def.VehicleClass( 1, 1, 1, "Auto" );
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
		printHL( "-" );
	}

	/**
		Quit.
	**/
	public function quit() {
		Sys.exit( 0 );
	}



	// HELPERS ------------------------------------------------------------------


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

}