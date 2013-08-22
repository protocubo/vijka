package test.unit;

import def.*;
import graph.adjLists.*;

class TestNewDigraph extends TestCase {

	public function testQueueHas() {
		var node = new def.Node( 1, 1, 1 );
		var vertex = new Vertex( node );
		var Q = new Queue( 2, 32 );
		assertFalse( Q.has( vertex ) );
		Q.put( vertex );
		assertTrue( Q.has( vertex ) );
		Q.extract();
		assertFalse( Q.has( vertex ) );
	}

}
