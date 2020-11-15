package haxe.unit.macros;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.TypeTools;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;

class CherryPick {

    /**
     * Pick up certain tests of other TestCase class(es) to be tested.
     * This uses a macro, and the syntax is peculiar:
     * @example
     * function test_othertests_from_here_and_there() {
     *      cherrypick(
     *          new TestFoo().test_some_method,
     *          new sodium.test.TestRandomness().test_critical
     *      );
     * }
     * @endexample
     * @param (ExprOf<TestCase>) You must pass `this` here (you always call
     *             this from a TestCase). 
     * @param () - There is no [] even though it's an array (because macro)
     *           - You have to use notation `new pack.Classname().test_xxx`,
     *             It is a way to make sure the classname with given
     *             method exist at compilation time.
     *             The package is optional. The classname and methodname
     *             will be used to create the TestResult object and report
     *             error in case assertions inside the picked up test(s)
     *             fail.
     *
     * @see TestCase.subCases() to run ALL tests of certain class(es) instead.
     */
    public static macro function assertTests(
        thisTestCase : haxe.macro.ExprOf<haxe.unit.TestCase>,
        a            : Array<haxe.macro.Expr>
    ) {
        try {
            if (thisTestCase.toString() != "this")
                throw "When using `haxe.unit.macros.assertTests(this, ...)`, 
                    please don't forget the `this`";
            var a : Array<{ className:String, methName: String }> =
                haxe.unit.macros
                 .CherryPick
                 .extract_and_check_existence_of_classes_and_method_names(a);
            return macro for (o in $v{a}) {
                var caseTest = Type.createInstance(
                    Type.resolveClass(o.className), 
                    []
                );
                var oldClassname = caseTest.currentTest;
                caseTest.currentTest = $thisTestCase.currentTest;
                caseTest.currentTest.classname = o.className;
                caseTest.currentTest.method = o.methName;
                caseTest.setup();
                var f = Reflect.field(caseTest, o.methName);
                if (f == null) 
                    throw o.className + "." + o.methName + " not found! This is an
                        anomaly and should not have happened. Watchdog 38222";
                Reflect.callMethod(caseTest, f, []);
                caseTest.tearDown();
                caseTest.currentTest = oldClassname;
            }
        }
        catch (d:Dynamic) { 
            Context.fatalError(
                Std.string(d), 
                Context.currentPos()
            ); 
            return macro null; 
        }
    }
    
    /**
     * The two points of this macro is 1/ to extract
     * class and method names as String, and
     * 2/ to fail if any component such 
     * as `new pack1.TestA.test_me()` 
     * doesn't exist. The `new ` is cosmetic here,
     * we only enforce this notation so as enforce
     * a haxe compatible syntax to designate a class and 
     * a member method.
     * @param (Array<Void->Void>) Something like [
     *     new pack1.TestA().test_me,
     *     new pack1.TestA().test_you,
     *     new pack2.TestB().test_it,
     * ]
     * @return Something like [
     *     { className:"pack1.TestA", methName: "test_me" },
     *     { className:"pack1.TestA", methName: "test_you" },
     *     { className:"pack2.TestB", methName: "test_it" }
     * ]
     */ 
#if macro
    public static function
        extract_and_check_existence_of_classes_and_method_names(
            a:Array<Expr>
    ) : Array<{ className:String, methName:String }>
        return a.map( function(e) {
                var er = ~/new ([a-zA-Z0-9._]*)\(\)\.(test[a-zA-Z0-9_]*)/;
                if (!er.match(e.toString())) {
                    throw '${e.toString()} didn\'t match a format 
                            such as new pack.ClassName.test_foo'; 
                }
                else {
                    var o = {
                        className: er.matched(1), 
                        methName: er.matched(2)
                    }
                    var t;
                    try t = Context.getType(o.className)
                    catch (d:Dynamic) throw "`" + e.toString() + "`: " 
                                         + Std.string(d);
                    switch t {
                        case TInst(refClassType, aArgs):
                            if (TypeTools.findField(
                                    refClassType.get(), 
                                    o.methName
                            ) == null)
                                throw "`new " +o.className+"()." +o.methName 
                                    +"`: Class " + o.className 
                                    + " found, but it has no method called " 
                                    + o.methName; 
                        case _:
                            throw "`new "+o.className+"()."+o.methName 
                                +"`: Class " + o.className + " not found";
                    }
                    return o;
                }
            });
#end
}


