package haxe.unit;

import Reflect;

/**
 * This class runs unit test cases and prints the result.
 * ```haxe
 * var r = new haxe.unit.TestRunner();
 * r.add(new MyTestCase());
 * // add other TestCases here
 * 
 * // finally, run the tests
 * r.run();
 * ```
 * @see <https://haxe.org/manual/std-unit-testing.html>
*/
class TestRunner {

	// The unit test results. 
    // Available after the `run()` is called.
	public var result(default, null) : TestResult;

	var cases  : List<TestCase>;

	public function new() {
		result = new TestResult();
		cases = new List();
	}

	/**
	 * Add TestCase instances to the unit test.
     * TestCase.subCases(a:Array<TestCase>) can 
     *   be overriden for these elements 
     *   to also be added when this method is called.
	 */
	public function add( c:TestCase ) : Void {
		cases.add(c);
        for (subcase in c.subCases())
            cases.add(subcase);
	}

	/**
     * Runs the unit tests and prints the results.
	 * @return `true` if the unit test succesfully executed the test cases.
	 */
	public function run() : Bool {
		result = new TestResult();
		for ( c in cases ){
			runCase(c);
		}
		print(result.toString());
		return result.success;
	}

	function runCase( t:TestCase ) : Void 	{
		var old = haxe.Log.trace;
		haxe.Log.trace = customTrace;

		var cl = Type.getClass(t);
		var fields = Type.getInstanceFields(cl);

		print( "Class: "+Type.getClassName(cl)+" ");
		for ( f in fields ){
			var fname = f;
			var field = Reflect.field(t, f);
			if ( StringTools.startsWith(fname,"test") && Reflect.isFunction(field) ){
				t.currentTest = new TestStatus();
				t.currentTest.classname = Type.getClassName(cl);
				t.currentTest.method = fname;
				t.setup();

				try {
					Reflect.callMethod(t, field, new Array());

					if( t.currentTest.done ){
						t.currentTest.success = true;
						print(".");
					}else{
						t.currentTest.success = false;
						t.currentTest.error = "(warning) no assert";
						print("W");
					}
				}catch ( e : TestStatus ){
					print("F");
					t.currentTest.backtrace = haxe.CallStack.toString(haxe.CallStack.exceptionStack());
				}catch ( e : Dynamic ){
					print("E");
					#if js
					if( e.message != null ){
						t.currentTest.error = "exception thrown : "+e+" ["+e.message+"]";
					}else{
						t.currentTest.error = "exception thrown : "+e;
					}
					#else
					t.currentTest.error = "exception thrown : "+e;
					#end
					t.currentTest.backtrace = haxe.CallStack.toString(haxe.CallStack.exceptionStack());
				}
				result.add(t.currentTest);
				t.tearDown();
			}
		}

		print("\n");
		haxe.Log.trace = old;
	}

    #if flash static var tf : flash.text.TextField = null; #end

	/**
	 *	Prints the given object/value.
	 *	- Flash outputs the result in a new `TextField` on stage.
	 *	- JavaScript outputs the result using `console.log`.
	 *	- Other targets use native `print` to output the result.
	 *	This function is `dynamic` so it can be overriden in custom setups.
	**/
	public static dynamic function print( v : Dynamic ) untyped {
		#if flash
			if( tf == null ) {
				tf = new flash.text.TextField();
				tf.selectable = false;
				tf.width = flash.Lib.current.stage.stageWidth;
				tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
				flash.Lib.current.addChild(tf);
			}
			tf.appendText(v);
		#elseif neko
			__dollar__print(v);
		#elseif php
			php.Lib.print(v);
		#elseif cpp
			cpp.Lib.print(v);
		#elseif js
			var msg = js.Boot.__string_rec(v,"");
			var d;
			if( __js__("typeof")(document) != "undefined"
				&& (d = document.getElementById("haxe:trace")) != null ) {
				msg = StringTools.htmlEscape(msg).split("\n").join("<br/>");
				d.innerHTML += msg+"<br/>";
			}
			else if (  __js__("typeof process") != "undefined"
					&& __js__("process").stdout != null
					&& __js__("process").stdout.write != null)
				__js__("process").stdout.write(msg); // node
			else if (  __js__("typeof console") != "undefined"
					&& __js__("console").log != null )
				__js__("console").log(msg); // document-less js (which may include a line break)
		#elseif cs
			cs.system.Console.Write(v);
		#elseif java
			var str:String = v;
			untyped __java__("java.lang.System.out.print(str)");
		#elseif python
			python.Lib.print(v);
		#elseif (hl || lua)
			Sys.print(Std.string(v));
		#end
	}

	private static function customTrace( v, ?p : haxe.PosInfos ) {
		print(p.fileName+":"+p.lineNumber+": "+Std.string(v)+"\n");
	}

}
