import exceptions;
import std.conv : to;
import std.stdio : writeln, writefln;

import evaluate : evaluate;

version (unittest) {
	// This is required for `silly`.
} else {
	int main(string[] args) {

		if (args.length != 2) {
			debug {
				string sampleExpr = "1 * 2";
				if (args.length > 2) {

					args[1] = sampleExpr;
				} else {
					args ~= sampleExpr;
				}
			} else {
				writeln("USAGE: meval <expression>");
				return 1;
			}
		}

		try {
			float answer = evaluate(args[1]);
			writefln("\n\t%s = %s", args[1], answer);
		} catch (exceptions.InvalidCharacter ex) {

			import std.format : format;

			auto invalidCharPointer = new char[ex.colNum];
			foreach (ref c; invalidCharPointer) {
				c = ' ';
			}
			invalidCharPointer[$ - 1] = '^';

			writeln(format("ERROR: %s", ex.msg));
			writeln("\n\t", args[1]);
			writeln("\t", to!string(invalidCharPointer));
		}
		return 0;
	}
}
