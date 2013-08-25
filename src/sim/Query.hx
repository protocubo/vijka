package sim;

import hscript.Expr;
import hscript.Interp;
import hscript.Parser;

import Lambda.has;

class Query {

	private var interp:Interp;

	private var idName:String;
	private var exactAlias:Null<String>;
	private var exactId:Null<Dynamic>;
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
		interp.variables.set( "in", function (x:Dynamic,it:Iterable<Dynamic>) return has(it,x) );
	}

	public static function prepare( s:String, id:String ):Query {
		var ast = parse( s );
		return new Query( ast, id );
	}

	private static function parse( s:String ):Expr {
		var p = new Parser();
		return p.parseString( s );
	}

	public function execute( index:Map<Dynamic,Dynamic>
	, ?aliases:Map<String,Dynamic> ):Iterable<Dynamic> {
		var res = [];
		// trace( exactId );
		// trace( exactAlias );
		if ( exactAlias != null ) {
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
		case EIdent("alias"): throw "`alias` can only be used once and with the '==' operator";
		case EIdent(v): EField(EIdent("__record__"),v);
		// case EVar(n,t,e): EVar(n,t,remap(e));
		// case EParent(e): EParent(remap(e));
		// case EBlock(e): EBlock(e.map(remap));
		// case EField(e,f): EField(remap(e),f);
		case EBinop(op,e1,e2): remapBinop(ast);
		// case EUnop(op,preffix,e): EUnop(op,preffix,remap(e));
		case ECall(EIdent("in"),params): ECall(EIdent("in"),params.map(remap));
		// case ECall(e,params): ECall(remap(e),params.map(remap));
		// case EIf(cond,e1,e2): EIf(remap(cond),remap(e1),remap(e2));
		// case EWhile(cond,e): EWhile(remap(cond),remap(e));
		// case EFor(v,it,e): EFor(v,remap(it),remap(e));
		// case EBreak:
		// case EContinue:
		// case EFunction(args,e,name,ret): EFunction(args,remap(e),name,ret);
		// case EReturn(e): EReturn(remap(e));
		case EArray(e,index): EArray(remap(e),remap(index));
		case EArrayDecl(e): EArrayDecl(e.map(remap));
		// case ENew(cl,params): ENew(cl,params.map(remap));
		// case EThrow(e): EThrow(remap(e));
		// case ETry(e,v,t,ecatch): ETry(remap(e),v,t,remap(ecatch));
		// case EObject(fl): EObject(fl.map( function (f) return { name:f.name, e:remap(f.e) } ) );
		// case ETernary(cond,e1,e2): ETernary(remap(cond),remap(e1),remap(e2));
		case all: throw "Bad expression: "+all;
		};
	}

	private function remapBinop( binop:Expr ):Expr {
		return switch ( binop ) {
		case EBinop("==",EConst(ct), EIdent("alias")):
			remapBinop( EBinop("==",EIdent("alias"),EConst(ct)) );
		case EBinop("==",EIdent("alias"),EConst(ct)):
			if ( exactAlias == null ) {
				exactAlias = switch ( ct ) {
				case CInt(v): Std.string( v );
				case CFloat(v): Std.string( v );
				case CString(v): v;
				}
				EBinop("==",EIdent("true"),EIdent("true"));
			}
			else {
				throw "`alias` can only be used (once) to match a constant";
			}
		case EBinop("==",EConst(CInt(v)),EIdent(name)):
			remapBinop( EBinop("==",EIdent(name),EConst(CInt(v))) );
		case EBinop("==",EIdent(name),EConst(CInt(v))):
			if ( name == idName ) {
				if ( exactId != null )
					exactId = v;
				EBinop("==",remap(EIdent("id")),EConst(CInt(v)));
			}
			else
				EBinop("==",remap(EIdent(name)),EConst(CInt(v)));
		case EBinop(op,e1,e2) if (has(["==","!="],op)): EBinop(op,remap(e1),remap(e2));
		case EBinop(op,e1,e2) if (has([">","<",">=","<="],op)): EBinop(op,remap(e1),remap(e2));
		case EBinop(op,e1,e2) if (has(["&&","||"],op)): EBinop(op,remap(e1),remap(e2));
		case EBinop("=",_,_): throw "Assignment '=' operator not allowed; did you mean to use the equality operator '=='?";
		case EBinop(op,_,_): throw "Operator '"+op+"' not allowed";
		case all: throw "Expression processing error: "+all;
		};
	}

}
