package haxe.unit;

import haxe.CallStack;
import haxe.PosInfos;

/**
 * The status information of a unit test case method.
 * @see <https://haxe.org/manual/std-unit-testing.html>
*/
class TestStatus {
	/**
		`true` when the unit test is executed.
	**/
	public var done : Bool;

	/**
		`true` when succesfully unit tested.
	**/
	public var success : Bool;

	/**
		The error message of the unit test method.
	**/
	public var error : String;

	/**
		The method name of the unit test.
	**/
	public var method : String;

	/**
		The class name of the unit test.
	**/
	public var classname : String;

	/**
		The position information of the unit test.
	**/
	public var posInfos : PosInfos;

	/**
		The representation of the stack exception.
	**/
	public var backtrace : String;

	public function new() 	{
		done = false;
		success = false;
	}
}
