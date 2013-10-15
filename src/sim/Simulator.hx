package sim;

import haxe.io.Input;
import haxe.io.Output;
import haxe.io.StringInput;
import sim.Algorithm;

import Lambda.list;

class Simulator {

	public var state:SimulatorState;
	public var profiling:Null<String>;
	public var log:Array<String>;

	public var screenSize:Int;

	public var underlyingInput:haxe.io.Input;

	public var online:Bool;

	private function new( _underlyingInput:haxe.io.Input, _screenSize ) {
		screenSize = _screenSize;
		underlyingInput = _underlyingInput;
		online = false;
		reset();
	}

	public function reset() {
		if ( state != null )
			state.invalidate();
		state = state != null ? new SimulatorState( this, state.newline
		                                          , sim.state.timing
		                                          , sim.state.identation
		                                          , ADijkstra
		                                          , sim.state.heapArity
		                                          , sim.state.heapReserve )
                            : new SimulatorState( this, baseNewline
		                                          , false // timing off by default
		                                          , 0 // no identation
		                                          , ADijkstra
		                                          , 3 // optimal b*log(N,b)
		                                          , 16 ); // reasonable considering
                                                       // Array doublying with push 

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

	public static inline var SHORTNAME = "Vijka";
	public static inline var FULLNAME = "Vijka - Demand model for highway tolls on regional road networks";
	public static inline var COPYRIGHT = "Copyright 2013, Jonas Malaco Filho and Arthur Campora Szász, Elebeta";
	public static inline var LICENSE = "Licensed under the BSD 3-clause license: http://opensource.org/licenses/BSD-3-Clause";
	public static inline var VERSION = "v1.1.1";
	public static inline var COMMIT_HASH = utils.GitVersion.describe(20);
	public static inline var BUILD_TIME = utils.BuildMacros.now();
	public static inline var BUILD_USERNAME = utils.BuildMacros.username();
	public static inline var BUILD_HOSTNAME = utils.BuildMacros.hostname();
	public static inline var BUILD_SYSNAME = utils.BuildMacros.systemName();
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

	private static inline var TABSIZE = 3;

	public static function tabs( n:Int ) {
		return StringTools.rpad( "", " ", TABSIZE*n );
	}

	public static function rawPrint( s:String, ?err=false ) {
		var stream = err ? stderr : stdout;
		stream.writeString( s );
		stream.flush();
	}

	public static function print( s:String, ?err=false ) {
		var stream = err ? stderr : stdout;
		if ( sim.state.identation < 0 )
			sim.state.identation = 0;
		var ident = sim.state.identation;

		var data = list( s.split( " " ) );

		var buf = new StringBuf();
		buf.add( tabs( ident ) );

		var dump = false;
		while ( data.length > 0 ) {
			if ( dump || buf.length >= sim.screenSize ) {
				stream.writeString( buf.toString()+baseNewline );
				buf = new StringBuf();
				buf.add( tabs( ident ) );
				dump = false;
			}
			var rem = sim.screenSize - buf.length;
			var d = data.pop();
			if ( d.length < rem ) {
				buf.add( d );
				if ( data.length > 0 && buf.length < sim.screenSize )
					buf.add( " " );
			}
			else if ( d.length < sim.screenSize - TABSIZE*ident ) {
				data.push( d );
				dump = true;
			}
			else {
				buf.add( d.substr( 0, rem ) );
				data.push( d.substr( rem+1 ) );
				dump = true;
			}
		}

		if ( buf.length > 0 )
			stream.writeString( buf.toString() );
		stream.flush();
	}

	public static function printr( s:String, ?err=false ) {
		var stream = err ? stderr : stdout;
		stream.writeString( "\r" );
		print( s, err );
		stream.flush();
	}
	
	public static function println( s:String, ?err=false ) {
		print( s+baseNewline, err );
	}

	public static function printrln( s:String, ?err=false ) {
		printr( s+baseNewline, err );
	}
	
	public static function printHL( s:String, ?err=false ) {
		println( StringTools.rpad( "", s, sim.screenSize - 2*TABSIZE*sim.state.identation ), err );
	}

	public function getArgs( inp:Input, newline:String ):Array<String> {
		var reader = new format.csv.Reader( inp, newline, " ", "'" );
		var args = reader.readRecord();
		if ( args.length>0 && args[0].length>0 && args[0].charCodeAt(0)=="#".code )
			return [];
		else
			return args;
	}

	public function strArgs( args:Array<String> ):String {
		var buf = new haxe.io.BytesOutput();
		new format.csv.Writer( buf, "\n", " ", "'" ).writeRecord( args );
		var bufStr = buf.getBytes().toString();
		return bufStr.substr( 0, bufStr.length - 1 );
	}
	
	private static var stdin = Sys.stdin();
	
	private static var stdout = Sys.stdout();
	
	private static var stderr = Sys.stderr();

	public function run( args:Array<String>, reading:Bool, time:Bool, hl:Bool ) {
		while ( args.remove( "" ) ) {}
		if ( args.length != 0 ) {
			var d = new mcli.Dispatch( args );
			var a = new SimulatorAPI( sim, reading );
			sim.startProfiling();
			var t0 = haxe.Timer.stamp();
			d.dispatch( a, false );
			var dt = haxe.Timer.stamp() - t0;
			sim.stopProfiling();
			sim.log.push( strArgs( args ) );
			if ( time ) println( "Done in "+dt+" seconds" );
			if ( hl ) printHL( "-" );
		}
	}

	public static var sim:Simulator;
	public static var baseNewline:String;
	
	private static function main() {

		baseNewline = ( PLATFORM == "Java" && Sys.systemName() == "Windows" ) ? "\r\n" : "\n";
		sim = new Simulator( stdin, 80 );

		if ( Sys.args().length > 0 ) {
			println( ":: "+Sys.args().join( " " ) );
			sim.run( Sys.args(), true, false, false );
		}

		printHL( "=" );
		new SimulatorAPI( sim, true ).welcomeInfo();
		printHL( "-" );
		println( "Type the desired options (and their arguments) bellow, or --help for usage information..." );
		printHL( "=" );

		sim.online = true;

		while ( true ) {
			try {
				print( "> " );
				var r = sim.getArgs( stdin, baseNewline );
				sim.run( r, false, sim.state.timing, true );
			}
			catch ( e:haxe.io.Eof ) {
				sim.stopProfiling();
				println( "" );
				Sys.exit( 0 );
			}
			catch ( e:mcli.DispatchError ) {
				sim.stopProfiling();
				sim.state.identation = 0;
				println( "Interface error: "+e );
			}
			catch ( e:Dynamic ) {
				sim.stopProfiling();
				sim.state.identation = 0;
				print( "ERROR: "+e );
				println( haxe.CallStack.toString( haxe.CallStack.exceptionStack() ) );
			}
		}
	}

}
