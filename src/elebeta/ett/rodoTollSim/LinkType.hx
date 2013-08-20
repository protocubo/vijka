package elebeta.ett.rodoTollSim;

import format.ett.Data;

class LinkType {
	public var id:Int;
	public var name:Null<String>;


	public static function ettFields():Array<Field> {
		return [
			new Field( "id", TInt ),
			new Field( "name", TNull(TString) )
		];
	}

	public static function makeEmpty():LinkType {
		return new LinkType();
	}

	public static function make( id, ?name ):LinkType {
		var type = new LinkType();
		type.id = id;
		type.name = name;
		return type;
	}

	private function new() {}

}
