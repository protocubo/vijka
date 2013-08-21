package sim;

import sim.Algorithm;

class Simulator {

	public var inp:format.csv.Reader;

	public var state:SimulatorState;
	public var profiling:Null<String>;
	public var log:Array<String>;

	public var newline:String;
	public var screenSize:Int;

	public var underlyingInput:haxe.io.Input;

	public var online:Bool;

	public function new( _underlyingInput:haxe.io.Input, _newline, _screenSize ) {
		newline = _newline;
		screenSize = _screenSize;
		underlyingInput = _underlyingInput;
		prepareForInput();
		online = false;
		reset();
	}

	public function prepareForInput() {
		inp = new format.csv.Reader( underlyingInput, newline, " ", "'" );
	}

	public function reset() {
		state = new SimulatorState( newline, ADijkstra );
		log = [];
	}

	public function startProfiling() {
		#if cpp
		if ( profiling != null ) {
			var now = Date.now().getTime();
			var nowi = Std.int( 1e-3*now );
			var fpath = profiling+"_"+nowi+"_"+Math.round(now-1e3*nowi);
			cpp.vm.Profiler.start( fpath );
		}
		#end
	}

	public function stopProfiling() {
		#if cpp
		cpp.vm.Profiler.stop();
		#end
	}

	public static inline var VERSION = "0.0.1-alpha";
	public static inline var PLATFORM = #if neko
		                                  	"Neko";
		                                 #elseif cpp
		                                 	#if HXCPP_M64
		                                 		"C++ 64-bits";
		                                 	#else
		                                 		"C++";
		                                 	#end
		                                 #elseif java
		                                 	"Java";
		                                 #else
		                                 	"Unknown";
		                                 #end

	public static function print( s:String, ?err=false ) {
		var stream = err ? stderr : stdout;
		stream.writeString( s );
		stream.flush();
	}
	
	public static function println( s:String, ?err=false ) {
		print( s+"\n", err );
	}
	
	public static function printHL( s:String, ?err=false ) {
		println( StringTools.rpad( "", s, sim != null ? sim.screenSize : 80 ) );
	}
	
	private static var stdin = Sys.stdin();
	
	private static var stdout = Sys.stdout();
	
	private static var stderr = Sys.stderr();

	public function run( args:Array<String>, reading:Bool, time:Bool, hl:Bool ):Void {
		try {
			while ( args.remove( "" ) ) {}
			if ( args.length != 0 ) {
				var d = new mcli.Dispatch( args );
				var a = new SimulatorAPI( sim, reading );
				sim.startProfiling();
				var t0 = haxe.Timer.stamp();
				d.dispatch( a, false );
				var dt = haxe.Timer.stamp() - t0;
				sim.stopProfiling();
				sim.log.push( args.join( " " ) );
				if ( time ) println( "Done in "+dt+" seconds" );
				if ( hl ) printHL( "-" );
			}
		}
		catch ( e:mcli.DispatchError ) {
			sim.stopProfiling();
			println( "Interface error: "+e );
			if ( hl ) printHL( "-" );
		}
		catch ( e:Dynamic ) {
			sim.stopProfiling();
			sim.log.push( args.join( " " ) );
			print( "ERROR: "+e );
			println( haxe.CallStack.toString( haxe.CallStack.exceptionStack() ) );
			if ( hl ) printHL( "-" );
		}
	}

	public static var sim:Simulator;
	
	private static function main() {

		var initialNewline = ( PLATFORM == "Java" && Sys.systemName() == "Windows" ) ? "\r\n" : "\n";
		sim = new Simulator( stdin, initialNewline, 80 );

		if ( Sys.args().length > 0 ) {
			println( ":: "+Sys.args().join( " " ) );
			sim.run( Sys.args(), true, false, false );
		}

		printHL( "=" );
		println( "Welcome to the RodoTollSim!" );
		println( "Type the desired options (and their arguments) bellow, or --help for usage information..." );
		printHL( "=" );

		sim.online = true;

		while ( true ) {
			try {
				print( "> " ); stdout.flush();
				var r = sim.inp.readRecord();
				sim.run( r, false, true, true );
			}
			catch ( e:haxe.io.Eof ) {
				sim.stopProfiling();
				println( "" );
				Sys.exit( 0 );
			}
		}
	}

}
