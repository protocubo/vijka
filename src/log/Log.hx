package log;

import haxe.io.Output;
import haxe.PosInfos;
import haxe.Timer;

class Log {

	var start:Float;
	var output:Output;

	static
	var instance:Log;

	public
	function logMesssage( m:String, ?pos:PosInfos ) {
		output.writeString( '${uptime()}s: ${pos.className}: ${pos.methodName}: $m\n' );
	}
	
	public static
	function prepare( output:Output, ?pos:PosInfos ) {
		if ( instance != null )
			throw "Log already set";
		instance = new Log( output );
		log( "Vijka log started at "+Date.now(), pos );
	}

	public static
	function getInstance() {
		if ( instance == null )
			throw "Log not set";
		return instance;
	}

	public static
	function log( message:String, ?pos:PosInfos ) {
		getInstance().logMesssage( message, pos );
	}

	function new( o:Output ) {
		output = o;
		start = Timer.stamp();
	}

	function uptime() {
		return Timer.stamp() - start;
	}

}