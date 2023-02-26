module evaluate;

import tokenizer : Tokenizer;
import parser : Parser;

debug {
    import expr : Binary, Number, Unary, Group;
}

/** Evaluates the given expression. */
float evaluate(string expression) {

    auto tokens = new Tokenizer(expression).tokenize();
    auto expr = new Parser(tokens).parse();
    return expr.evaluate();
}

@("Integration")
unittest {
    import std.exception;
    import std.math;
    import std.format;

    string failed = "Failed %s";

    string expression = "1 + 2 + 3";
    assert(evaluate(expression) == 6.0, format(failed, expression));

    expression = "(1 + 2) / 3 + 4";
    assert(evaluate(expression) == 5, format(failed, expression));

    expression = "((3 - 9) / 6 * 5)";
    assert(evaluate(expression) == -5), format(failed, expression);
}
