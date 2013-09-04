package elebeta.ett.vijka;

import format.ett.Data;

class LinkType {
	public var id:Int;
	public var name:Null<String>;

	public function toString() {
		return 'Link type \'$id\'\n  => name: "$name"';
	}

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
