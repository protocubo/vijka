package tools;

import sys.io.Process;

import sim.Simulator.println;

class Ogr2Ogr {

	public static
	function json2shp( destPath:String, srcPath:String, ?overwrite=false ):Bool {
		var args = overwrite ? [ "-overwrite" ] : [];
		args = args.concat( [ "-f", "ESRI Shapefile", destPath, srcPath ] );
		var p = spawn( args );
		try {
			while ( true )
				println( p.stderr.readLine() );
		} catch ( e:haxe.io.Eof ) { }
		var exitCode = p.exitCode();
		p.close();
		println( "`ogr2ogr` exited with status "+exitCode+" ("+(exitCode==0?"success":"error")+")" );
		return exitCode == 0;
	}

	static
	function spawn( args:Array<String> ):Process {
		if ( args.length == 0 )
			throw "No arguments to ogr2ogr";
		println( "Running `ogr2ogr` with parameters: `"+args.join("`, `")+"`" );
		return new Process( "ogr2ogr", args );
	}

}
