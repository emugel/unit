package haxe.unit;

/**
	TestResult contains the result of the executed unit tests.
**/
class TestResult {
	var m_tests : List<TestStatus>;

	/**
		`true` if the unit test succesfully executed the test cases.
	**/
	public var success(default, null) : Bool;

	public function new() {
		m_tests = new List();
		success = true;
	}

	public function add( t:TestStatus ) : Void {
		m_tests.add(t);
		if( !t.success )
			success = false;
	}

	/**
		String representation from the result of the unit test.
	**/
	public function toString() : String 	{
		var buf = new StringBuf();
		var failures = 0;
		for ( test in m_tests ){
			if (test.success == false){
				buf.add("* ");
				buf.add(test.classname);
				buf.add("::");
				buf.add(test.method);
				buf.add("()");
				buf.add("\n");

				buf.add("ERR: ");
				if( test.posInfos != null ){
					buf.add(test.posInfos.fileName);
					buf.add(":");
					buf.add(test.posInfos.lineNumber);
					buf.add("(");
					buf.add(test.posInfos.className);
					buf.add(".");
					buf.add(test.posInfos.methodName);
					buf.add(") - ");
				}
				buf.add(test.error);
				buf.add("\n");

				if (test.backtrace != null) {
					buf.add(test.backtrace);
					buf.add("\n");
				}

				buf.add("\n");
				failures++;
			}
		}
		buf.add("\n");
		if (failures == 0)
			buf.add("OK ");
		else
			buf.add("FAILED ");

		buf.add(m_tests.length);
		buf.add(" tests, ");
		buf.add(failures);
		buf.add(" failed, ");
		buf.add( (m_tests.length - failures) );
		buf.add(" success");
		buf.add("\n");
		return buf.toString();
	}

}
