package blah;

import def.*;

import graph.linkList.Arc;
import graph.linkList.Digraph;
import graph.linkList.Vertex;
import sim.Simulator;

class CompileSim {

	@:access( graph.linkList.Digraph )
	function new() {
		var d = new Digraph();

		var v1 = d.addVertex( new Node( 1, 10, 10 ) );
		var v2 = d.addVertex( new Node( 2, 20, 20 ) );
		trace( [v1,v2] );

		var auto = new VehicleClass( 1, 1, 1, "Auto" );

		var as1 = new Speed();
		as1.set( auto, 60 );
		var a1 = d.addArc( new Link( 10, v1.node, v2.node, 10, as1, 5 ) );
		var as2 = new Speed();
		as2.set( auto, 80 );
		var a2 = d.addArc( new Link( 20, v2.node, v1.node, 10, as2, 5 ) );
		trace( [as1,as2] );
		trace( [a1,a2] );

		d.simpleSSSPT( v1.node, 1.5, auto, new UserCostModel( 1.2, .3, 1 ), null );
		trace( [ v1.dist, v1.time, v1.toll, v1.cost, v1.parent != null ? v1.parent.from.node.id : null ] );
		trace( [ v2.dist, v2.time, v2.toll, v2.cost, v2.parent != null ? v2.parent.from.node.id : null ] );

		#if cpp
		cpp.vm.Profiler.start( "hxcpp_profiling" );
		#end
		trace( "******        TEST PATHS        ******" );
		var v = 10;
		var a = 20;
		for ( n in 1...5 ) {
			v *= 10;
			a *= 10;
			trace( '====== #v=$v, #a=$a ======' );
			var d = new graph.linkList.Digraph();
			trace( 'initialized a new digraph' );
			var t0 = haxe.Timer.stamp();
			for ( i in 0...v )
				d.addVertex( new def.Node( i, i, i ) );
			var tel = haxe.Timer.stamp() - t0;
			trace( 'added $v vertices in $tel' );
			var auto = new def.VehicleClass( 1, 1, 1, "Auto" );
			var speed = new def.Speed();
			speed.set( auto, 60 );
			t0 = haxe.Timer.stamp();
			for ( i in 0...a ) {
				var s = d.vs.get( Std.random( v ) );
				var t = s;
				while ( s == t )
					t = d.vs.get( Std.random( v ) );
				d.addArc( new def.Link( i, s.node, t.node, Math.random()*10, speed, 0. ) );
			}
			tel = haxe.Timer.stamp() - t0;
			trace( 'added $a arcs in $tel' );
			t0 = haxe.Timer.stamp();
			var ucost = new def.UserCostModel( 1., 0., 0. );
			for ( i in 0...10 ) {
				var s = d.vs.get( i );
				d.simpleSSSPT( s.node, 0., auto, ucost );
			}
			tel = haxe.Timer.stamp() - t0;
			trace( 'ran 10 single source shortest paths in $tel' );
			trace( '... ${tel/10} per source, on average' );
			trace( "" );
		}
		#if cpp
		cpp.vm.Profiler.stop();
		#end
	}

	static function main() {
		var app = new CompileSim();
	}
}
