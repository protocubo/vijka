package utils;

import haxe.macro.Expr;
import haxe.macro.Context;

class GitVersion {

	public static macro function describe( ?len:Int=40, ?path:String=".", ?exec:String= "git" ):ExprOf<String> {
		var cwd = Sys.getCwd();
		Sys.setCwd( path );
		var uuid = "";

		var p = new sys.io.Process( exec, 'describe --abbrev=$len --dirty=+ --long --always'.split(" ") );
		var code = p.exitCode();
		if ( code != 0 )
			throw "git returned "+code;
		var hash = p.stdout.readLine().toString();
		p.close();

		Sys.setCwd( cwd );

		return { expr: EConst( CString( hash ) ), pos: Context.currentPos() };
	}

	public static macro function head( ?len:Int=40, ?path:String=".", ?exec:String= "git" ):ExprOf<String> {
		var cwd = Sys.getCwd();
		Sys.setCwd( path );
		var uuid = "";

		var p = new sys.io.Process( exec, 'log -1 --format=%h --abbrev=$len'.split(" ") );
		var code = p.exitCode();
		if ( code != 0 )
			throw "git returned "+code;
		var hash = p.stdout.readLine().toString();
		p.close();

		Sys.setCwd( cwd );

		return { expr: EConst( CString( hash ) ), pos: Context.currentPos() };
	}

}
