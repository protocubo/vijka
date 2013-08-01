package blah;

import sys.db.Connection;
import sys.db.Manager;
import sys.db.Sqlite;
import sys.db.TableCreate;

class CompileSPOD {

	static var tables:Array<Dynamic> = [
		spod.Link,
		spod.LinkType,
		spod.Node,
		spod.TypeSpeed,
		spod.VehicleClass,
	];

	function new() {
		initSPOD();
	}

	function initSPOD():Void {
		sys.FileSystem.deleteFile( "compile_spod_test.db" );
		Manager.cnx = Sqlite.open( "compile_spod_test.db" );
		Manager.initialize();
		for ( t in tables )
			if ( !TableCreate.exists( t.manager ) ) {
				trace( 'Creating table ${Type.getClassName(t)}' );
				TableCreate.create( t.manager );
			}
			else {
				trace( 'Skipping table ${Type.getClassName(t)}' );
			}
	}	

	static function main() {
		var app = new CompileSPOD();
	}

}
