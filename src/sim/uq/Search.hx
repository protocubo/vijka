package sim.uq;

import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import elebeta.ett.rodoTollSim.*;

import Lambda.has;
import Lambda.map;

import sim.Simulator.print;
import sim.Simulator.printHL;
import sim.Simulator.println;

class Search {

	private var interp:Interp;

	private var idName:String;
	private var exactAlias:Null<String>;
	private var exactId:Null<Dynamic>;
	private var findPath:Null<{vehicleId:Int,nodeIds:Array<Int>}>;
	private var ast:Expr;

	private function new( _ast, _idName ) {
		exactAlias = null;
		exactId = null;
		idName = _idName;
		ast = remap( _ast );
		// trace( _ast );
		// trace( ast );
		interp = new Interp();
		registerCustomNames();
	}

	private function registerCustomNames() {
		interp.variables.set( "found", found );
	}

	private function found( instance:Dynamic, set:Iterable<Dynamic> ) {
		return has( set, instance );
	}

	private function sp( sim:Simulator, vehicleId:Int, nodeIds:Iterable<Int> ):Iterable<Link> {
		var path:Array<Link> = [];
		var output:SimulatorState = Type.createEmptyInstance( SimulatorState );
		output.results = new Map();
		sim.state.assemble( false, false );
		var pre:Node = null;
		for ( id in nodeIds ) {
			var node = sim.state.nodes.get( id );
			if ( node == null ) throw "No node '"+id+"'";
			if ( pre != null ) {
				var fakeOd = OD.make(0,0,0,0,vehicleId,null,1,0,0,1,pre.point,node.point,null,null);
				fakeOd.tollWeight = 0;
				sim.state.digraph.run( [ fakeOd ], false, true, output, false );
				var r = output.results.get(0);
				if ( !r.ran || r.path == null || r.path.length == 0 ) // only !r.ran should be enough
					continue;
				else if ( !r.reached )
					throw "Could not find a path between '"+pre.id+"' and '"+node.id+"'";
				else {
					var rpath = r.path.map( sim.state.links.get );
					if ( path.length > 0
					&& rpath[0].startNodeId != path[path.length - 1].finishNodeId )
						throw "Could not join paths at '"+rpath[0].startNodeId
						+"'-'"+path[path.length - 1].finishNodeId+"'";
					else
						path = path.concat( rpath );
				}
				output.results.remove( 0 );
			}
			pre = node;
		}
		var ext = 0.;
		for ( link in path ) ext += link.extension;
		println( "Got "+path.length+" links, resulting in a path extension of "+ext );
		return path;
	}

	public static function prepare( s:String, id:String ):Search {
		var ast = parse( s );
		return new Search( ast, id );
	}

	private static function parse( s:String ):Expr {
		var p = new Parser();
		return p.parseString( s );
	}

	public function execute( sim:Simulator, index:Map<Dynamic,Dynamic>
	, ?aliases:Map<String,Dynamic> ):Iterable<Dynamic> {
		interp.variables.set( "__sim__", sim );
		var res:Array<Dynamic> = []; // typing this result is important otherwise this method gets specialized for Java (cannot cast Node to Link errors)
		// trace( exactId );
		// trace( exactAlias );
		if ( findPath != null ) {
			if ( exactAlias != null )
				throw "Cannot use alias in conjunction with sp";
			for ( link in sp( sim, findPath.vehicleId, findPath.nodeIds ) ) {
				interp.variables.set( "__record__", link );
				if ( interp.execute( ast ) == true )
					res.push( link );
			}
		}
		else if ( exactAlias != null ) {
			if ( aliases == null )
				throw "No alias available";
			var alias:Iterable<Int> = aliases.get( exactAlias );
			if ( alias == null )
				return [];
			for ( rid in alias ) {
				if ( !index.exists( rid ) )
					throw "No object for id '"+rid+"' from alias '"+exactAlias+"'";
				var r = index.get( rid );
				interp.variables.set( "__record__", r );
				if ( interp.execute( ast ) == true )
					res.push( r );
			}
		}
		else if ( exactId != null ) {
			if ( index.exists( exactId ) ) {
				var r = index.get( exactId );
				interp.variables.set( "__record__", r );
				if ( interp.execute( ast ) == true )
					res = [ index.get( exactId ) ];
			}
		}
		else {
			for ( r in index ) {
				interp.variables.set( "__record__", r );
				if ( interp.execute( ast ) == true )
					res.push( r );
			}
		}
		return res;
	}

	private function remap( ast:Null<Expr> ):Null<Expr> {
		return switch ( ast ) {
		case null: null;
		case EConst(_): ast;

		case EIdent("alias"):
			throw "`alias` can only be used once and with the '==' operator";
		case EIdent(v):
			EField(EIdent("__record__"),v);

		case EBinop(op,e1,e2):
			remapBinop(ast);

		case ECall(EIdent("found"),params):
			ECall(EIdent("found"),params.map(remap));
		case ECall(EIdent("sp"),[EConst(CInt(vid)),EArrayDecl(e)]):
			if ( findPath != null )
				throw "Can only search links in path once";
			findPath = { vehicleId: vid, nodeIds: e.map( function ( _e ) return switch ( _e ) {
				case EConst(CInt(nid)): nid;
				case all: throw "Invalid node id '"+all+"'";
				} )
			};
			EBinop("==",EIdent("true"),EIdent("true"));

		// case EArray(e,index): EArray(remap(e),remap(index));
		case EArrayDecl(e): EArrayDecl(e.map(remap));

		case all: throw "Bad expression: "+all;
		};
	}

	private function remapBinop( binop:Expr ):Expr {
		return switch ( binop ) {
		case EBinop("==",EConst(ct), EIdent("alias")):
			remapBinop( EBinop("==",EIdent("alias"),EConst(ct)) );
		case EBinop("==",EIdent("alias"),EConst(ct)):
			if ( exactAlias != null )
				throw "`alias` can only be used (once) to match a constant";	
			exactAlias = switch ( ct ) {
			case CInt(v): Std.string( v );
			case CFloat(v): Std.string( v );
			case CString(v): v;
			};
			EBinop("==",EIdent("true"),EIdent("true"));

		case EBinop("==",EConst(CInt(v)),EIdent(name)):
			remapBinop( EBinop("==",EIdent(name),EConst(CInt(v))) );
		case EBinop("==",EIdent(name),EConst(CInt(v))):
			if ( name == idName ) {
				if ( exactId != null )
					exactId = v;
				EBinop("==",remap(EIdent(name)),EConst(CInt(v)));
			}
			else
				EBinop("==",remap(EIdent(name)),EConst(CInt(v)));

		case EBinop(op,e1,e2) if (has(["==","!="],op)):
			EBinop(op,remap(e1),remap(e2));
		case EBinop(op,e1,e2) if (has([">","<",">=","<="],op)):
			EBinop(op,remap(e1),remap(e2));
		case EBinop(op,e1,e2) if (has(["&&","||"],op)):
			EBinop(op,remap(e1),remap(e2));

		case EBinop("=",_,_):
			throw "Assignment '=' operator not allowed; did you mean to use the equality operator '=='?";
		case EBinop(op,_,_):
			throw "Operator '"+op+"' not allowed";
		case all:
			throw "Expression processing error: "+all;
		};
	}

}
