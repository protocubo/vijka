package sim;

import sim.Simulator;

class ScriptingEngine {

	var parser:hscript.Parser;
	var interpreter:hscript.Interp;

	public
	function new() {
		prepareParser();
		prepareInterpreter();
	}

	public
	function execute( script:String ) {
		interpreter.execute( parser.parseString( script ) );
	}

	function prepareParser() {
		parser = new hscript.Parser();
	}

	function prepareInterpreter() {
		interpreter = new hscript.Interp();
		interpreter.variables.set( "Lambda", Lambda );
		interpreter.variables.set( "Math", Math );
		interpreter.variables.set( "Console", {
			println: function (x:Dynamic) Simulator.println( Std.string(x), false )
		} );
		interpreter.variables.set( "Simulator", {
			startProfiling: Simulator.sim.startProfiling,
			stopProfiling: Simulator.sim.stopProfiling,
			getState: function () return Simulator.sim.state
		} );

	}

}
