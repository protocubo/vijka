package elebeta.ett.vijka;

import format.ett.Data;

class Link {

	public var id:Int;
	public var startNodeId:Int; // Node::id
	public var finishNodeId:Int; // Node::id
	public var extension:Float;
	public var typeId:Int; // LinkType::id
	public var toll:Float;

	public inline function toString() {
		return 'Link \'$id\', from node \'$startNodeId\' to node \'$finishNodeId\'\n'
		+'  => extension: $extension, type: $typeId, toll: $toll';
	}

	public inline function jsonBody():String {
		return '"id":$id,"startNodeId":$startNodeId,"finishNodeId":$finishNodeId,"extension":$extension,"typeId":$typeId,"toll":$toll';
	}

	public static function ettFields():Array<Field> {
		return [
			new Field( "id", TInt ),
			new Field( "startNodeId", TInt ),
			new Field( "finishNodeId", TInt ),
			new Field( "extension", TFloat ),
			new Field( "typeId", TInt ),
			new Field( "toll", TFloat )
		];
	}

	public static inline function makeEmpty():Link {
		return new Link();
	}

	public static inline function make( id, startNodeId, finishNodeId, extension, typeId, toll ):Link {
		var link = new Link();
		link.id = id;
		link.startNodeId = startNodeId;
		link.finishNodeId = finishNodeId;
		link.extension = extension;
		link.extension = extension;
		link.typeId = typeId;
		link.toll = toll;
		return link;
	}

	private inline function new() {}

}
