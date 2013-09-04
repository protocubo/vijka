package utils;

import haxe.macro.Expr;
import haxe.macro.Context;

class GitVersion {
	public static macro function get( ?len:Int=40, ?path:String=".", ?exec:String= "git" ):ExprOf<String> {
		var cwd = Sys.getCwd();
		Sys.setCwd( path );
		var uuid = "";

		var p = new sys.io.Process( exec, "describe --abbrev=40 --always --dirty=-dirty".split(" ") );
		var code = p.exitCode();
		if ( code != 0 )
			throw "git returned "+code;
		var hash = p.stdout.readAll().toString();
		p.close();

		var reg = ~/^(.+)-dirty$/;
		if ( reg.match( hash ) )
			hash = reg.matched( 1 ).substr( 0, len )+"+";
		else {
			hash = hash.substr( 0, len );
		}

		Sys.setCwd( cwd );

		return { expr: EConst( CString( hash ) ), pos: Context.currentPos() };
	}
}
