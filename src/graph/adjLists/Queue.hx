package graph.adjLists;

@:access( graph.adjLists.Vertex )
class Queue extends elebeta.ds.heap.DAryHeap<Vertex> {

	public function new( arity, reserve ) {
		super( arity, reserve );
	}

	override inline public function checkPredicate( a:Vertex, b:Vertex ):Bool {
		return a.est <= b.est;
	}
	
	override inline public function getIndex( e:Vertex ):Int {
		return e.index;
	}

	override inline public function saveIndex( e:Vertex, i:Int ):Void {
		e.index = i;
	}

	override inline public function clearIndex( e:Vertex ):Void {
		e.index = -1;
	}

	override inline public function contains( e:Vertex ):Bool {
		var i = e.index;
		return i >= 0 && i < length && h[i] == e;
	}

}
