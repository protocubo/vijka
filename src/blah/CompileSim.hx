package blah;

import def.Speed;
import def.UserCost;
import def.VehicleClass;
import graph.linkList.Vertex;
import graph.linkList.Arc;
import graph.linkList.Digraph;

import def.Node;
import def.Link;

import sim.Simulator;

class CompileSim {
	function new() {
		var d = new Digraph();

		var v1 = d.addVertex( new Node( 1, 10, 10 ) );
		var v2 = d.addVertex( new Node( 2, 20, 20 ) );
		trace( [v1,v2] );

		var as1 = new Speed();
		as1.set( Auto, 60 );
		var a1 = d.addArc( new Link( 10, v1.node, v2.node, 10, as1, 5, Math.POSITIVE_INFINITY ) );
		var as2 = new Speed();
		as2.set( Auto, 80 );
		var a2 = d.addArc( new Link( 20, v2.node, v1.node, 10, as2, 5, Math.POSITIVE_INFINITY ) );
		trace( [as1,as2] );
		trace( [a1,a2] );

		d.spt( v1.node, Auto, new UserCost( 1.2, 1.3 ), null );
		trace( [ v1.dist, v1.time, v1.toll, v1.cost, v1.parent != null ? v1.parent.node.id : null ] );
		trace( [ v2.dist, v2.time, v2.toll, v2.cost, v2.parent != null ? v2.parent.node.id : null ] );
	}

	static function main() {
		var app = new CompileSim();
	}
}
