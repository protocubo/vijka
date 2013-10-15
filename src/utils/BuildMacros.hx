package utils;

import haxe.macro.Expr;

class BuildMacros {

	public static macro
	function now():ExprOf<Float> {
		var t = Date.now().getTime();
		return macro $v{t};
	}

	public static macro
	function username():ExprOf<String> {
		var n = switch ( Sys.systemName() ) {
		case "Linux": Sys.getEnv( "USER" );
		case "Windows": Sys.getEnv( "USERNAME" );
		case all: "unknown";
		};
		return macro $v{n};
	}

	public static macro
	function hostname():ExprOf<String> {
		var n = switch ( Sys.systemName() ) {
		case "Linux", "Windows":
			var p = new sys.io.Process( "hostname", [] );
			var ret = p.stdout.readLine();
			p.exitCode();
			ret;
		case all: "unknown";
		};
		return macro $v{n};
	}

	public static macro
	function systemName():ExprOf<String> {
		var ret = Sys.systemName();
		return macro $v{ret};
	}

}
