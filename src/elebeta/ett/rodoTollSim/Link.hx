package elebeta.ett.rodoTollSim;

import format.ett.Data;

class Link {

	public var id:Int;
	public var startNodeId:Int;
	public var finishNodeId:Int;
	public var extension:Float;
	public var typeId:Int;
	public var toll:Float;

	public function jsonBody():String {
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

	public static function makeEmpty():Link {
		return new Link();
	}

	public static function make( id, startNodeId, finishNodeId, extension, typeId, toll ):Link {
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

	private function new() {}

}
