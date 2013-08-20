package sim;

class Simulator {

	public var state:SimulatorState;
	public var profiling:Null<String>;
	public var log:Array<String>;

	public function new() {
		reset();
	}

	public function reset() {
		state = new SimulatorState();
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
		                                 #elseif jva
		                                 	"Java";
		                                 #else
		                                 	"Unknown";
		                                 #end

	public static function print( s:String, ?err=false ) {
		( err ? stderr : stdout ).writeString( s );
	}
	
	public static function println( s:String, ?err=false ) {
		print( s+"\n", err );
	}
	
	public static function printHL( s:String, ?err=false ) {
		println( StringTools.rpad( "", s, 80 ) );
	}
	
	private static var stdin = Sys.stdin();
	
	private static var stdout = Sys.stdout();
	
	private static var stderr = Sys.stderr();

	public function run( args:Array<String>, reading:Bool ):Void {
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
				println( "Took "+dt+" seconds" );
			}
		}
		catch ( e:mcli.DispatchError ) {
			sim.stopProfiling();
			println( "Interface error: "+e );
		}
		catch ( e:Dynamic ) {
			sim.stopProfiling();
			print( "ERROR: "+e );
			println( haxe.CallStack.toString( haxe.CallStack.exceptionStack() ) );
		}
	}

	public static var sim:Simulator;
	
	private static function main() {
		if ( Sys.args().length > 0 )
			throw "Cannot yet run in batch mode";

		var inp = new format.csv.Reader( stdin, "\n", " ", "'" );
		sim = new Simulator();

		printHL( "=" );
		println( "Welcome to the RodoTollSim!" );
		println( "Type the desired options (and their arguments) bellow, or --help for usage information..." );
		printHL( "=" );

		while ( true ) {
			try {
				print( "> " ); stdout.flush();
				var r = inp.readRecord();
				sim.run( r, false );
			}
			catch ( e:haxe.io.Eof ) {
				sim.stopProfiling();
				println( "" );
				Sys.exit( 0 );
			}
		}
	}

}
