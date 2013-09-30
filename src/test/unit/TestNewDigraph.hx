package test.unit;

import def.*;
import graph.adjLists.*;

class TestNewDigraph extends TestCase {

	public function testQueueContains() {
		var node = new def.Node( 1, 1, 1 );
		var vertex = new Vertex( node );
		var Q = new Queue( 2, 32 );
		assertFalse( Q.contains( vertex ) );
		Q.add( vertex );
		assertTrue( Q.contains( vertex ) );
		Q.pop();
		assertFalse( Q.contains( vertex ) );
	}

}
