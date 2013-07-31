package test.unit;

import def.*;
import graph.linkList.*;

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

	@:access( graph.linkList.PseudoArc )
	@:access( graph.linkList.Vertex )
	public function testClearState() {
		var d = minorGraph();
		var vs = [ for ( v in d.vertices() ) v ];
		assertEquals( 3, vs.length );

		var dirtyVertex = function ( v:Vertex ):Void {
			v.dist = 20.;
			v.time = 30.;
			v.toll = 10.;
			v.cost = 100.;
			v.selectedToll = true;
			v.parent = new PseudoArc( vs[0] );
		};

		var checkVertex = function ( v:Vertex ) {
			assertPosInfinite( v.dist );
			assertPosInfinite( v.time );
			assertPosInfinite( v.toll );
			assertPosInfinite( v.cost );
			assertFalse( v.selectedToll );
			assertEquals( null, v.parent );

			// also, to avoid known NaN comparisson issues, no cost should be NaN ever
			assertFalse( Math.isNaN( v.dist ) );
			assertFalse( Math.isNaN( v.time ) );
			assertFalse( Math.isNaN( v.toll ) );
			assertFalse( Math.isNaN( v.cost ) );
		};

		dirtyVertex( vs[1] );
		vs[1].clearState();
		checkVertex( vs[1] );

		for ( v in d.vertices() )
			dirtyVertex( v );
		d.clearState();
		for ( v in d.vertices() )
			checkVertex( v );
	}

	@:access( graph.linkList.PseudoArc )
	@:access( graph.linkList.Vertex )
	public function testRevPathFold() {
		var d = minorGraph();
		var vs = [ for ( v in d.vertices() ) v ];
		vs.sort(
			function ( a:Vertex, b:Vertex )
				return Reflect.compare( a.node.id, b.node.id )
		);
		assertEquals( 3, vs.length );

		d.clearState();

		vs[0].parent = new PseudoArc( vs[0] );
		vs[0].cost = 1.;

		vs[1].parent = [ for ( a in d.arcs() ) if ( a.from == vs[0] && a.to == vs[1] ) a ].pop();
		vs[1].cost = 10.;
		
		vs[2].parent = null;
		vs[2].cost = 100.;

		var countFold = function ( current:Arc, pre:Int ):Int {
			return pre + 1;
		};

		var count = function ( i:Int ) {
			return d.revPathFold( vs[i].node, countFold, 0 );
		};

		assertEquals( 1, count( 0 ) );
		assertEquals( 2, count( 1 ) );
		assertEquals( null, count( 2 ) );

		var pathFold = function ( current:Arc, pre:List<Vertex> ):List<Vertex> {
			pre.push( current.to );
			return pre;
		};

		var path = function ( i:Int ) {
			var pathList = d.revPathFold( vs[i].node, pathFold, new List() );
			return pathList != null ? [ for ( v in pathList ) v.node.id ] : [];
		};

		assertEqualArrays( [0], path( 0 ) );
		assertEqualArrays( [0, 1], path( 1 ) );
		assertEqualArrays( [], path( 2 ) );
	}

	@:access( graph.linkList.Digraph )
	@:access( graph.linkList.Vertex )
	public function testSingleRelaxation() {
		// some nodes
		var node1 = new Node( 0, .5, -.5 );
		var node2 = new Node( 1, 1.5, -1.5 );

		// some links
		var speed = function ( sval:Float ) {
			var s = new Speed();
			s.set( Auto, sval );
			return s;
		};
		var link12 = new Link( 0, node1, node2, 1., speed( .1 ), .5, 10. );
		var link21 = new Link( 1, node2, node1, 1., speed( .1 ), .5, 10. );

		var d = new Digraph();
		d.addVertex( node1 );
		d.addVertex( node2 );
		d.addArc( link12 );
		d.addArc( link21 );

		var checkRelax = function ( d:Digraph, link:Link, tollMulti:Float
		, vclass:def.VehicleClass, ucost:UserCostModel, selectedToll:Link ):Void {
			var a = d.getArc( link );
			d.relax( a, tollMulti, vclass, ucost, selectedToll );
			// trace( [ a.to.dist, a.to.time, a.to.toll, a.to.cost, a.to.selectedToll, a.to.parent != null ] );
			if ( a.to.parent == a ) { // arc relaxed
				assertEquals( a.from.selectedToll || a.link == selectedToll
				, a.to.selectedToll );
				assertEquals( a.from.dist+a.link.dist, a.to.dist );
				assertEquals( a.from.time+a.time( vclass ), a.to.time );
				assertEquals( a.from.toll+a.toll( tollMulti ), a.to.toll );
				assertEquals( ucost.userCost( a.to.dist, a.to.time, a.to.toll )
				, a.to.cost );
			}
			else if ( a.from.parent == null ) { // arc not yet reached
				assertEquals( null, a.to.parent );
			}
			else { // arc not relaxed
				assertTrue( ucost.userCost( a.from.dist+a.link.dist
				            , a.from.time+a.time( vclass ), a.from.toll+a.toll( tollMulti ) )
				>= a.to.cost );
			}
			// also, to avoid known NaN comparisson issues, no cost should be NaN ever
			assertFalse( Math.isNaN( a.to.dist ) );
			assertFalse( Math.isNaN( a.to.time ) );
			assertFalse( Math.isNaN( a.to.toll ) );
			assertFalse( Math.isNaN( a.to.cost ) );
		};

		// valid input
		d.clearState();
		d.setVertexInitialState( node1, 0., 0., 0., 0. );
		d.getVertex( node1 ).selectedToll = true;
		checkRelax( d, link12, 3.14, Auto, new UserCostModel( 2.72, .52, 1.1 ), null );
		checkRelax( d, link21, 3.14, Auto, new UserCostModel( 2.72, .52, 1.1 ), null );
		d.clearState();
		d.setVertexInitialState( node1, 0., 0., 0., 0. );
		checkRelax( d, link12, 3.14, Auto, new UserCostModel( 2.72, .52, 1.1 ), link12 );
		checkRelax( d, link21, 3.14, Auto, new UserCostModel( 2.72, .52, 1.1 ), link21 );

		// invalid input
		d.clearState();
		d.setVertexInitialState( node1, 0., 0., 0., 0. );
		assertEquals( null, d.getVertex( node2 ).parent );
		checkRelax( d, link12, 3.14, LargeTruck, new UserCostModel( 2.72, .52, 1.1 ), null );
		assertEquals( null, d.getVertex( node2 ).parent );
	}

	function minorGraph():Digraph {
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
		var link3 = new Link( 2, node1, node3, 2., speed( .5 ), 0., 15. );

		// vertex insertion
		var d = new Digraph();
		d.addVertex( node1 );
		d.addVertex( node2 );
		d.addVertex( node3 );

		// arc insertion
		d.addArc( link1 );
		d.addArc( link2 );
		d.addArc( link3 );

		return d;
	}

}
