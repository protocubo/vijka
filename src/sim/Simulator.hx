package sim;

/**
	RodoTollSim
**/
class Simulator extends mcli.CommandLine {

	/**
		Print usage
	**/
	public function help() {
		println( this.showUsage() );
	}

	/**
		Quit
	**/
	public function quit() {
		Sys.exit( 0 );
	}

	/**
		Run the unit tests
	**/
	public function unitTests() {
		println( "Running the unit tests" );
		printHL( "-" );
		var app = new test.unit.UnitTests();
		app.run();
		printHL( "-" );
	}

	/**
		Run the unit tests
	**/
	public function test() {
		throw "";
	}

	private static var stdin = Sys.stdin();
	private static var stdout = Sys.stdout();
	private static var stderr = Sys.stderr();

	private static function print( s:String, ?err=false ) {
		( err ? stderr : stdout ).writeString( s );
	}

	private static function println( s:String, ?err=false ) {
		print( s+"\n", err );
	}

	private static function printHL( s:String, ?err=false ) {
		println( StringTools.rpad( "", s, 80 ) );
	}

	private static function main() {
		if ( Sys.args().length > 0 )
			throw "Cannot yet run in batch mode";

		var inp = new format.csv.Reader( stdin, "\n", " ", "'" );
		var x = new Simulator();

		printHL( "=" );
		println( "Welcome to the RodoTollSim!" );
		println( "Type the desired options (and their arguments) bellow, or --help for usage information..." );
		printHL( "=" );

		while ( true ) {
			try {
				print( "> " );
				var r = inp.readRecord();

				while ( r.remove( "" ) ) {}
				if ( r.length != 0 )
					new mcli.Dispatch( r ).dispatch( x, false );
			}
			catch ( e:haxe.io.Eof ) {
				println( "" );
				Sys.exit( 0 );
			}
			catch ( e:mcli.DispatchError ) {
				println( "Interface error: "+e );
			}
			catch ( e:Dynamic ) {
				print( "ERROR: "+e );
				println( haxe.CallStack.toString( haxe.CallStack.exceptionStack() ) );
			}
		}
	}

}
