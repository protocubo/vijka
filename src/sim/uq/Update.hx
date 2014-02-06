package sim.uq;

import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import Lambda.has;
import sim.SimulatorState;
import Type;

class Update {

	private var interp:Interp;

	private var fields:Iterable<String>;
	private var ast:Expr;

	private var context:SimulatorState;

	private function new( _ast, _allowedFields, context ) {
		this.context = context;
		fields = _allowedFields;
		ast = remap( _ast );
		// trace( _ast );
		// trace( ast );
		interp = new Interp();
		registerCustomNames();
	}

	private function registerCustomNames() {
		interp.variables.set( "findType", exp_findType );
		interp.variables.set( "getSpeed", exp_getSpeed );
	}

	public static function prepare( s:String, allowedFields:Iterable<String>, context:SimulatorState ):Update {
		var ast = parse( s );
		return new Update( ast, allowedFields, context );
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

	function exp_findType( vehicleId:Null<Int>, speed:Null<Float> ):Null<Int> {
		if ( vehicleId == null || Type.typeof( vehicleId ) != TInt )
			throw 'Bad vehicle id $vehicleId';
		else if ( !context.vehicles.exists( vehicleId ) )
			throw  'Unknown vehicle id $vehicleId';
		if ( speed == null || ( Type.typeof( speed ) != TFloat && Type.typeof( speed ) != TInt ) )
			throw 'Bad speed $speed';
			
		var typeId:Null<Int> = null;
		var best = Math.POSITIVE_INFINITY;
		for ( s in context.speeds ) {
			if ( s.vehicleId == vehicleId ) {
				var d = Math.abs( s.speed - speed );
				if ( d < best ) {
					best = d;
					typeId = s.typeId;
				}
			}
		}
		// trace( 'vehicleId=$vehicleId, speed=$speed => typeId=$typeId' );
		return typeId;
	}

	function exp_getSpeed( vehicleId:Null<Int>, typeId:Null<Int> ):Null<Float> {
		if ( vehicleId == null || Type.typeof( vehicleId ) != TInt )
			throw 'Bad vehicle id $vehicleId';
		else if ( !context.vehicles.exists( vehicleId ) )
			throw  'Unknown vehicle id $vehicleId';
		if ( typeId == null || Type.typeof( typeId ) != TInt )
			throw 'Bad type id $typeId';
		else if ( !context.linkTypes.exists( typeId ) )
			throw  'Unknown type id $typeId';

		var speed:Null<Float> = null;
		for ( s in context.speeds ) {
			if ( s.vehicleId == vehicleId && s.typeId == typeId ) {
				speed = s.speed;
				break;
			}
		}
		// trace( 'vehicleId=$vehicleId, typeId=$typeId => speed=$speed' );
		return speed;
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
		case EBinop(op,e1,e2):
			switch ( op ) {
			case "=": EBinop(op, remap(e1),remap(e2));
			case "+=", "-=", "*=", "/=": EBinop(op, remap(e1),remap(e2));
			case "+", "-", "*", "/": EBinop(op, remap(e1),remap(e2));
			case all: throw "Operator \""+op+"\" not supported";
			}
		// case EUnop(op,preffix,e): EUnop(op,preffix,remap(e));
		case ECall(EIdent("findType"),params): ECall(EIdent("findType"),params.map(remap));
		case ECall(EIdent("getSpeed"),params): ECall(EIdent("getSpeed"),params.map(remap));
		case ECall(i,params): throw 'Bad function name $i';
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
