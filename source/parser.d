import tokenizer : Token;
import enums : TokenType;
import expr : Expression, Number, Unary, Binary, Group;
import std.conv;
import std.format : format;

version (unittest) {
    import std.exception;

    import tokenizer : Tokenizer, Token;
}

class Parser {
    private Token[] _tokens;
    private int _current = 0;

    this(Token[] tokens) {
        _tokens = tokens;
    }

    this() {
    }

    /** Parses the given tokens and returns the corresponding
    expression. */
    Expression parse() {

        return expression();
    }

    void reset(Token[] tokens) {
        this._tokens = tokens;
        this._current = 0;
    }

    private Expression expression() {

        return term();
    }

    private Expression term() {
        auto expr = factor();

        while (match(TokenType.PLUS, TokenType.MINUS)) {

            Token currToken = getCurrToken();
            advance();
            auto rightOperand = factor();
            expr = new Binary(expr, rightOperand, currToken);
        }

        return expr;

    }

    private Expression factor() {
        auto expr = unary();

        while (match(TokenType.DIVIDE, TokenType.MULTIPLY)) {
            Token currToken = getCurrToken();
            advance();
            auto rightOperand = unary();
            expr = new Binary(expr, rightOperand, currToken);
        }

        return expr;

    }

    private Expression unary() {

        if (match(TokenType.PLUS, TokenType.MINUS)) {
            Token currToken = getCurrToken();
            advance();
            return new Unary(unary(), currToken);
        }

        return primary();
    }

    private Expression primary() {

        if (match(TokenType.NUMBER)) {
            auto token = getCurrToken();
            advance();
            return new Number(to!float(token.value));
        }

        if (match(TokenType.LEFT_PARAN)) {
            advance();
            auto expr = expression();
            if (!match(TokenType.RIGHT_PARAN)) {
                throw new Exception("parse error");
            }
            advance();
            import std.stdio;

            return new Group(expr);
        }

        assert(0);
    }

    // ----- Helpers -----

    /** Returns the current token to be parsed. */
    private Token getCurrToken() {
        return _tokens[_current];
    }

    /** Returns `True` if all the tokens have been parsed. */
    private bool isAtEnd() {
        return _current >= _tokens.length;
    }

    /** Advances the current tokens pointer by one. */
    private void advance() {
        _current++;
    }

    /** Returns `True` if the token type of the current token
    matches any of the given token types. */
    private bool match(TokenType[] tokenTypes...) {
        if (isAtEnd())
            return false;

        Token token = getCurrToken();
        foreach (TokenType tokenType; tokenTypes) {

            if (token.tokenType == tokenType) {

                return true;
            }
        }
        return false;
    }

}

@("Only a number")
unittest {

    // 1
    auto tokens = [Token(TokenType.NUMBER, "1")];
    auto parsedExpr = new Parser(tokens).parse();

    assert(parsedExpr == new Number(1.0));
}

@("Unary")
unittest {

    // -1
    auto minusToken = Token(TokenType.MINUS, "-");
    auto tokens = [minusToken, Token(TokenType.NUMBER, "1")];
    auto parsedExpr = new Parser(tokens).parse();

    assert(parsedExpr == new Unary(
            new Number(1), minusToken
    ), "Failed on '-' unary operator");

    // +1
    auto plusToken = Token(TokenType.PLUS, "+");
    tokens = [plusToken, Token(TokenType.NUMBER, "1")];
    parsedExpr = new Parser(tokens).parse();

    assert(parsedExpr == new Unary(
            new Number(1), plusToken
    ), "Failed on '+' unary operator");
}

@("Binary")
unittest {

    // Setup
    auto plusToken = Token(TokenType.PLUS, "+");
    auto minusToken = Token(TokenType.MINUS, "-");
    auto multiplyToken = Token(TokenType.MULTIPLY, "*");
    auto divideToken = Token(TokenType.DIVIDE, "/");
    auto one = Token(TokenType.NUMBER, "1");
    auto two = Token(TokenType.NUMBER, "2");
    auto left = new Number(1);
    auto right = new Number(2);

    // 1 + 2
    auto tokens = [one, plusToken, two];
    auto expr = new Parser(tokens).parse();
    assert(expr == new Binary(left, right, plusToken));

    // 1 - 2
    tokens = [one, minusToken, two];
    expr = new Parser(tokens).parse();
    assert(expr == new Binary(left, right, minusToken));

    // 1 * 2
    tokens = [one, multiplyToken, two];
    expr = new Parser(tokens).parse();
    assert(expr == new Binary(left, right, multiplyToken));

    // 1 / 2
    tokens = [one, divideToken, two];
    expr = new Parser(tokens).parse();
    assert(expr == new Binary(left, right, divideToken));
}

@("Group")
unittest {

    // Setup
    auto leftParanToken = Token(TokenType.LEFT_PARAN, "(");
    auto rightParanToken = Token(TokenType.RIGHT_PARAN, ")");
    auto plusToken = Token(TokenType.PLUS, "+");
    auto minusToken = Token(TokenType.MINUS, "-");
    auto one = Token(TokenType.NUMBER, "1");
    auto two = Token(TokenType.NUMBER, "2");
    auto left = new Number(1);
    auto right = new Number(2);

    // Normal group
    // (1 + 2)
    auto tokens = [leftParanToken, one, plusToken, two, rightParanToken];
    auto expr = new Parser(tokens).parse();
    assert(expr == new Group(new Binary(left, right, plusToken)));

    // Nested group
    // (1 + (1 - 2))
    tokens = [
        leftParanToken, one, plusToken, leftParanToken, one, minusToken, two,
        rightParanToken, rightParanToken
    ];
    expr = new Parser(tokens).parse();
    assert(expr == new Group(
            new Binary(
            left,
            new Group(
            new Binary(left, right, minusToken)
            ),
            plusToken)
    ));

    // No right paranthesis
    // (1 + 2
    tokens = [leftParanToken, one, plusToken, two];
    auto parser = new Parser(tokens);
    assertThrown(parser.parse());

}

@("Complex")
unittest {

    // Test cases where there are more than two operands or one
    // operator per group
    auto oneToken = Token(TokenType.NUMBER, "1");
    auto oneNum = new Number(1);

    auto twoToken = Token(TokenType.NUMBER, "2");
    auto twoNum = new Number(2);

    auto threeToken = Token(TokenType.NUMBER, "3");
    auto threeNum = new Number(3);

    auto plusToken = Token(TokenType.PLUS, "+");
    auto divideToken = Token(TokenType.DIVIDE, "/");
    auto leftParanToken = Token(TokenType.LEFT_PARAN, "(");
    auto rightParanToken = Token(TokenType.RIGHT_PARAN, ")");

    // 1 + 2 + 3
    auto tokens = [
        oneToken, plusToken, twoToken, plusToken, threeToken
    ];
    auto expr = new Parser(tokens).parse();

    assert(expr == new Binary(
            new Binary(
            oneNum, twoNum, plusToken
        ),
        threeNum,
        plusToken
    ), "Failed 1 + 2 + 3");

    // 1 + 2 / 3 + 2 => 1 + (2/3) + 2 => (1 + (2/3)) + 2
    tokens = [
        oneToken, plusToken, twoToken, divideToken, threeToken, plusToken,
        twoToken
    ];
    expr = new Parser(tokens).parse();
    auto expectedExpr = new Binary(
        new Binary(
            oneNum,
            new Binary(twoNum, threeNum, divideToken),
            plusToken
    ),
    twoNum,
    plusToken
    );
    assert(expr == expectedExpr, "Failed on 1 + 2 / 3 + 2");

}
