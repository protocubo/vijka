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
		var x = new Simulator();
		printHL( "=" );
		println( "Welcome to the RodoTollSim!" );
		println( "Type the desired commands bellow..." );
		printHL( "=" );
		while ( true ) {
			print( "> " );
			var r = stdin.readLine();
			if ( r.length == 0 )
				continue;
			try {
			new mcli.Dispatch( r.split( " " ) ).dispatch( x, false );
			}
			catch ( e:mcli.DispatchError ) {
				println( "ERROR: "+e, false );
			}
		}
	}

}
