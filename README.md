Extension of the venerable haxe.unit package, which is legacy now.

The basics remain, it's a very simple sync unit test framework and its compatible with the original one. Of course there are much more powerful unit tests right now, and we use them on occasion, but the simplicity of haxe.unit is also nice to have.

In addition to the very slightly improved output, there are a few new capabilities that are listed below.

## TestCase of TestCases

Imagine a `libxyz` that comes with its own `TestCase` files (`TestA`, `TestB`, `TestC`).
It is possible to create a `TestLibxyz` that will have all 3 above cases and all their tests,
in a similar way to TestSuite in other frameworks. This allows for example a user of `libxyz` 
to simply add the `TestLibxyz` in its package and therefore duplicate the tests of `libxyz` 
there if that's what wanted (usually this is not the case).

To do this, you would simply override `subCases()`:

```haxe
package libxyz.test;
import libxyz.test.*;

class TestLibxyz extends haxe.unit.TestCase {
    public override function subCases() : Iterable<haxe.unit.TestCase>
        return [ 
            new libxyz.test.TestSimple(), 
            new libxyz.test.TestAdvanced() 
        ];
}
```
# Have a test, run other tests

A different use case from the above, even though it seems similar at first glance.

You may for instance have a production server that needs to run a small **subset**
of tests each time it starts, *not entire TestCases*, but only the very critical tests.

```
  - TestA extends TestCase
    - test_alphabet             // critical
    - test_betagam
    - test_gammadelt
  - TestB extends TestCase
    - test_berlin               // critical
    - test_baltimore
  - TestC extends TestCase
    - test_crustaceans
    - test_equinodermata        // critical
```

Now we could define `TestCritical` like so:
```haxe
package entirely.different.package;

class TestCritical {
    public function test_critical_precious_in_production() : Void {
        haxe.unit.macros.CherryPick.assertTests(
            this,
            new libabc.test.TestA().test_alphabet,
            new libabc.test.TestB().test_berlin,
            new libabc.test.TestA().test_equinodermata,
            new entirely.different.package.test.TestZ().test_server_has_qualified_name
        );
    } 
}
```

This way there is no need to recopy the tests (and even though it's a macro,
the macro don't duplicate the code either), and existence of the classes and
referenced tests is done at compile-time.

# Ability to filter tests to run & to show method names as they run

By using the `TestRunnerAdvanced` (a simple extension of `TestRunner`), 
it is possible to:

* filter tests to run (suggested cli syntax: `-o xxx -o yyy`)
* show method names as they run (suggested cli syntax: `-s`)

Note this framework does not yet implement the parsing from the cli,
it is your responsability to write (we may provide it later, but the
one we are using right now is still too tied to our application).

If you write one such `cli<->haxe.unit` system yourself, we also suggest 
to have, in addition to the above switches:
* `-a` :: to run all the tests (by default it should show a mere list of test cases)
* `-l` :: to list all tests in a TestCase.

Here are some examples (for a compiled binary called `xxx`):

```bash
foo                            # show help and list TestCases
foo TestBar                    # run all tests in TestBar 
foo testbar                    # same
foo bar                        # same!
foo bar -l                     # list tests in TestBar, don't run any
foo bar -o test_baz -o bazar   # only run test_baz and test_bazar
foo bar -s                     # run tests for TestBar and Show methods, instead of linear "."
foo bar pub -s                 # idem, but also run TestPub
foo -a                         # run all available test cases
foo -a -s                      # run all available test cases, Showing methods, instead of linear "."
```

# Other

* `TestCase.tempLocation()` gives OS temporary path location ($TEMP, or "/tmp/" or "." whichever exists first)

# License applying to all .hx files in src/

Copyright (C)2005-2017 Haxe Foundation
                                                                            
Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:
                                                                            
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
                                                                            
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
