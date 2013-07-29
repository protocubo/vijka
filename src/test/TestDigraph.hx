package test;

import def.Link;
import def.Node;
import def.Speed;
import def.VehicleClass;

import graph.linkList.Digraph;

class TestDigraph extends TestCase {

	public function testVertices() {
		// some nodes
		var node1 = new Node( 0, .5, -.5 );
		var node2 = new Node( 1, 1.5, -1.5 );
		var node1_2 = new Node( 0, .5, -.5 ); // id colision
		var node3 = new Node( 2, 2.5, -2.5 );

		// vertex insertion
		var d = new Digraph();
		assertEquals( node1, d.addVertex( node1 ).node );
		assertEquals( node2, d.addVertex( node2 ).node );
		assertAnyException( d.addVertex.bind( null ) );
		assertAnyException( d.addVertex.bind( node1_2 ) );

		// vertex querying
		assertEquals( node1, d.getVertex( node1 ).node );
		assertEquals( node2, d.getVertex( node2 ).node );
		assertEquals( null, d.getVertex( null ) );
		assertEquals( null, d.getVertex( node1_2 ) );
		assertEquals( null, d.getVertex( node3 ) );
		
		// vertex iteration
		var dns = [ for ( v in d.vertices() ) v.node.id ];
		dns.sort( Reflect.compare );
		assertEqualArrays( [ node1.id, node2.id ], dns );
	}

	public function testArcs() {
		// some nodes
		var node1 = new Node( 0, .5, -.5 );
		var node2 = new Node( 1, 1.5, -1.5 );
		var node3 = new Node( 2, 2.5, -2.5 );

		// some links
		var speed = function ( sval:Float ) {
			var s = new Speed();
			s.set( Auto, sval );
			return s;
		};
		var link1 = new Link( 0, node1, node2, 1., speed( .1 ), .5, 10. );
		var link2 = new Link( 1, node2, node1, 1., speed( .1 ), .5, 10. );
		var link1_2 = new Link( 0, node2, node1, 2., speed( .5 ), 0., 20. );
		var link3 = new Link( 2, node1, node3, 2., speed( .5 ), 0., 15. );

		// vertex insertion
		var d = new Digraph();
		d.addVertex( node1 );
		d.addVertex( node2 );

		// arc insertion
		assertEquals( link1, d.addArc( link1 ).link );
		assertEquals( link2, d.addArc( link2 ).link );
		assertAnyException( d.addArc.bind( null ) );
		assertAnyException( d.addArc.bind( link1_2 ) );
		assertAnyException( d.addArc.bind( link3 ) );

		// arc querying
		assertEquals( link1, d.getArc( link1 ).link );
		assertEquals( link2, d.getArc( link2 ).link );
		assertEquals( null, d.getArc( null ) );
		assertEquals( null, d.getArc( link1_2 ) );
		assertEquals( null, d.getArc( link3 ) );
		
		// arc iteration
		var das = [ for ( a in d.arcs() ) a.link.id ];
		das.sort( Reflect.compare );
		assertEqualArrays( [ link1.id, link2.id ], das );
	}

}
