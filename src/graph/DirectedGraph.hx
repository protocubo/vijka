package graph;

import def.Link;
import def.Node;
import def.UserCostModel;

interface DirectedGraph {

	public function addVertex( node:Node ):Void;

	public function addArc( link:Link ):Void;

	public function stpath( source:Node, destination:Node, ?costModel:UserCostModel ):Void;

	public function rpfold<T>( destination:Node, f:Arc->T->T, first:T ):T;

}
