package haxe.unit;

/**
 * Extending haxe.unit.TestRunner.
 * This allows capabilities for a CLI, for example 
 * you may define these switches:
 *
 * -s showing methods, 
 * -l listing methods,
 * -o <meth> running only a certain method.
 * -q being quiet about print()
 *
 * Then you can easily have these features
 * using new() arguments and addToRunOnlyFilter()
 */
class TestRunnerAdvanced extends haxe.unit.TestRunner {

    var _bShowMethods      : Bool;
    var _bQuiet            : Bool;
    var _bAll              : Bool;
    var _aOnlyThoseMethods : Array<String>;

    var _cbDebug : Null<String->Null<PosInfos>->Void>;

    public function new(bShowMethodNames:Bool=false, quiet:Bool=false, all:Bool=false, cbDebug:Null<String->Null<PosInfos>->Void>=null) {
        super();
        _bShowMethods      = bShowMethodNames;
        _bQuiet            = quiet;
        _bAll              = all;
        _aOnlyThoseMethods = null;
        _cbDebug           = cbDebug;
    }

    public function addToRunOnlyFilter(meth) : Void {
        debug("restricting to methods named: " + meth);
        if (_aOnlyThoseMethods == null) _aOnlyThoseMethods = [];
        if (_aOnlyThoseMethods.indexOf(meth) == -1)
            _aOnlyThoseMethods.push(meth);
    }

    public inline function print(v:Dynamic) 
        if (!_bQuiet) haxe.unit.TestRunner.print(v);

	override function runCase( t:haxe.unit.TestCase ) : Void 	{
		var old = haxe.Log.trace;
		haxe.Log.trace = haxe.unit.TestRunner.customTrace;

		var cl = Type.getClass(t);
		var fields = Type.getInstanceFields(cl);

        if (_bQuiet || _bAll || _bShowMethods) Sys.print( "Class: "+Type.getClassName(cl)+" ");
        else Sys.println( "Class: "+Type.getClassName(cl)+" ");

		for ( f in fields ){
			var fname = f;
			var field = Reflect.field(t, f);
			if ( StringTools.startsWith(fname,"test") && Reflect.isFunction(field) ){

                if (_aOnlyThoseMethods != null) {
                    if (_aOnlyThoseMethods.length == 0) {
                        Sys.print( "No method name matches" );
                        break;
                    }
                    else if (!Lambda.has(_aOnlyThoseMethods, fname)) {
                        debug("skipping " + fname);
                        continue;
                    }
                }

                if (_bShowMethods) Sys.print("\n  - \x1B[1m" + fname + "\x1B[0m ");
				t.currentTest = new haxe.unit.TestStatus();
				t.currentTest.classname = Type.getClassName(cl);
				t.currentTest.method = fname;
				t.setup();

				try {
					Reflect.callMethod(t, field, new Array());

					if( t.currentTest.done ){
						t.currentTest.success = true;
						Sys.print(".");
					}else{
						t.currentTest.success = false;
						t.currentTest.error = "(warning) no assert";
						Sys.print("W");
					}
				} catch ( e : haxe.unit.TestStatus ){
					Sys.print("F");
					t.currentTest.backtrace = haxe.CallStack.toString(haxe.CallStack.exceptionStack());
				} catch (e:cold.data.orderast.ScriptError) {
                    t.currentTest.error = e.toString() + " from " + e.pos();
					t.currentTest.backtrace = haxe.CallStack.toString(haxe.CallStack.exceptionStack());
				} catch (e:Dynamic) {
					Sys.print("E");
					#if js
					if( e.message != null ){
						t.currentTest.error = "exception thrown [in TestRunner]: "+e+" ["+e.message+"]";
					}else{
						t.currentTest.error = "exception thrown [in TestRunner]: "+e;
					}
					#else
					t.currentTest.error = "exception thrown [in TestRunner]: "+e;
					#end
                    #if !debug
                    Sys.println("Run with -D debug to get the call stack");
                    #end
					t.currentTest.backtrace = haxe.CallStack.toString(haxe.CallStack.exceptionStack());
				}
				result.add(t.currentTest);
				t.tearDown();
			}
		}

		if ( _bAll ) Sys.print("\n");
		haxe.Log.trace = old;
	}

    public function debug(msg:String, ?pos:haxe.PosInfos) : Void
        if (_cbDebug != null) _cbDebug(msg, pos);
}

