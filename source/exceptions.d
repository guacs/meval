module exceptions;
import std.stdio : writeln;
import std.format : format;

class InvalidCharacter : Exception {

    ulong colNum;

    this(char c, ulong colNum, string file = __FILE__, size_t line = __LINE__) {
        this.colNum = colNum;
        string errorMsg = format("Invalid character '%s' found at column number '%d'", c, colNum);
        super(errorMsg, file, line);
    }
}

class DivideByZero : Exception {

    this() {
        super("Tried to divide by zero!");
    }
}
