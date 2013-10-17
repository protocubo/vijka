package tools;

import sys.io.Process;

import sim.Simulator.println;

class Ogr2Ogr {

	public static
	function json2shp( destPath:String, srcPath:String, ?overwrite=false ):Int {
		var args = overwrite ? [ "-overwrite" ] : [];
		args = args.concat( [ "-f", "ESRI Shapefile", destPath, srcPath ] );
		var p = spawn( args );
		try {
			while ( true )
				println( p.stderr.readLine() );
		} catch ( e:haxe.io.Eof ) { }
		var exitCode = p.exitCode();
		p.close();
		return exitCode;
	}

	static
	function spawn( args:Array<String> ):Process {
		if ( args.length == 0 )
			throw "No arguments to ogr2ogr";
		println( "Running `ogr2ogr` with parameters: `"+args.join("`, `")+"`" );
		return new Process( "ogr2ogr", args );
	}

}
