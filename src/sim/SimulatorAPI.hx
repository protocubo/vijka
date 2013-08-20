package sim;

import elebeta.ett.rodoTollSim.*;
import haxe.io.Eof;
import sim.Simulator.print;
import sim.Simulator.printHL;
import sim.Simulator.println;
import sim.Simulator;
import Std.string;

class SimulatorAPI extends mcli.CommandLine {

	private var reading:Bool;
	private var sim:Simulator;

	public function new( _sim:Simulator, _reading:Bool ) {
		sim = _sim;
		reading = _reading;
		super();
	}

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
		sim.state.invalidate();
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

	/**
		Read links (reentrant); requires nodes and link types
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


	private static function readEtt( inputPath:String ):format.ett.Reader {
		return new format.ett.Reader( readFile( inputPath ) );
	}

	private static function readFile( inputPath:String ):sys.io.FileInput {
		if ( !sys.FileSystem.exists( inputPath ) )
			throw "File '"+inputPath+"' does not exist";
		if ( sys.FileSystem.isDirectory( inputPath ) )
			throw "Expected a file but found a folder: '"+inputPath+"'";
		return sys.io.File.read( inputPath, true );
	}

	private static function right( data:Dynamic, len:Int, ?pad=" " ):String {
		return StringTools.lpad( string( data ), pad, len );
	}

	private static function left( data:Dynamic, len:Int, ?pad=" " ):String {
		return StringTools.rpad( string( data ), pad, len );
	}

}
