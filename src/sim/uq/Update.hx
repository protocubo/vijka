package sim.uq;

import hscript.Expr;
import hscript.Interp;
import hscript.Parser;

import Lambda.has;

class Update {

	private var interp:Interp;

	private var fields:Iterable<String>;
	private var ast:Expr;

	private function new( _ast, _allowedFields ) {
		fields = _allowedFields;
		ast = remap( _ast );
		// trace( _ast );
		// trace( ast );
		interp = new Interp();
	}

	public static function prepare( s:String, allowedFields:Iterable<String> ):Update {
		var ast = parse( s );
		return new Update( ast, allowedFields );
	}

	private static function parse( s:String ):Expr {
		var p = new Parser();
		return p.parseString( s );
	}

	public function execute( records:Iterable<Dynamic> ):Void {
		for ( r in records ) {
			interp.variables.set( "__record__", r );
			interp.execute( ast );
		}
	}

	private function remap( ast:Null<Expr> ):Null<Expr> {
		return switch ( ast ) {
		case null: null;
		case EConst(_): ast;
		case EIdent(v): EField(EIdent("__record__"),v);
		// case EVar(n,t,e): EVar(n,t,remap(e));
		case EParent(e): EParent(remap(e));
		// case EBlock(e): EBlock(e.map(remap));
		// case EField(e,f): EField(remap(e),f);
		case EBinop(op,e1,e2): switch ( op ) {
		case "=": EBinop(op, remap(e1),remap(e2));
		case "+=", "-=", "*=", "/=": EBinop(op, remap(e1),remap(e2));
		case "+", "-", "*", "/": EBinop(op, remap(e1),remap(e2));
		case all: throw "Operator \""+op+"\" not supported";
		}
		// case EUnop(op,preffix,e): EUnop(op,preffix,remap(e));
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

}
