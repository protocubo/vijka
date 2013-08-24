package elebeta.ett.rodoTollSim;

import format.ett.Data;

class LinkAlias {

	public var name:String;
	public var linkId:Int;

	public function toString() {
		return 'Alias \'$name\'\n  => link id $linkId';
	}

	public static function ettFields():Array<Field> {
		return [
			new Field( "name", TString ),
			new Field( "linkId", TInt )
		];
	}

	public static function makeEmpty():LinkAlias {
		return new LinkAlias();
	}

	public static function make( name, linkId ):LinkAlias {
		var alias = new LinkAlias();
		alias.name = name;
		alias.linkId = linkId;
		return alias;
	}

	private function new() {}

}
