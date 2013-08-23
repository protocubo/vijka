package sim;

import hscript.Expr;
import hscript.Parser;
import hscript.Interp;

class Query {

	var ast:Expr;
	var interp:Interp;

	private function new( _ast ) {
		ast = _ast;
		interp = new Interp();
	}

	public function execute( o:Dynamic ) {
		interp.variables.set( "__record__", o );
		return interp.execute( ast );
	}

	public static function prepare<T>( s:String ):Query {
		var p = new Parser();
		var ast = remap( p.parseString( s ) );
		return new Query( ast );
	}

	public static function remap( ast:Null<Expr> ):Null<Expr> {
		return switch ( ast ) {
		case null: null;
		case EConst(_): ast;
		case EIdent(v): EIdent("__record__"+v);
		case EVar(n,t,e): EVar(n,t,remap(e));
		case EParent(e): EParent(remap(e));
		case EBlock(e): EBlock(e.map(remap));
		case EField(e,f): EField(remap(e),f);
		case EBinop(op,e1,e2): EBinop(op,remap(e1),remap(e2));
		case EUnop(op,preffix,e): EUnop(op,preffix,remap(e));
		case ECall(e,params): ECall(remap(e),params.map(remap));
		case EIf(cond,e1,e2): EIf(remap(cond),remap(e1),remap(e2));
		case EWhile(cond,e): EWhile(remap(cond),remap(e));
		case EFor(v,it,e): EFor(v,remap(it),remap(e));
		case EBreak:
		case EContinue:
		case EFunction(args,e,name,ret): EFunction(args,remap(e),name,ret);
		case EReturn(e): EReturn(remap(e));
		case EArray(e,index): EArray(remap(e),remap(index));
		case EArrayDecl(e): EArrayDecl(e.map(remap));
		case ENew(cl,params): ENew(cl,params.map(remap));
		case EThrow(e): EThrow(remap(e));
		case ETry(e,v,t,ecatch): ETry(remap(e),v,t,remap(ecatch));
		case EObject(fl): EObject(fl.map( function (f) return { name:f.name, e:remap(f.e) } ) );
		case ETernary(cond,e1,e2): ETernary(remap(cond),remap(e1),remap(e2));
		};
	}

}
