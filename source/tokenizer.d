module tokenizer;
import enums : TokenType;
import exceptions;
import std.ascii : isDigit;
import std.conv;
import std.stdio : writeln;

version (unittest) {
    import std.exception;
}

/** Representation of a single token. */
const struct Token {
    TokenType tokenType;
    string value;
}

/** Handles the tokenization of the expression.
*/
struct Tokenizer {

    private Token[] tokens = new Token[0];
    private int colNum = 0;
    private string expression;

    private immutable static char DOT = '.';
    private immutable static char SPACE = ' ';

    this(string expression) {
        this.expression = expression;

    }

    /** Tokenizes the given expression. */
    Token[] tokenize() {

        while (!isAtEnd()) {
            char c = getCurrChar();

            // Skipping whitespace.
            if (c == SPACE) {
                advance();
                continue;
            }

            if (isDigit(c) || c == DOT) {
                tokens ~= handleNumber();
            } else {
                tokens ~= handleOperator(c);
                advance();
            }
        }
        return tokens;
    }

    /** Handles numbers in the expression. */
    private Token handleNumber() {
        string num = getNumber();
        return Token(TokenType.NUMBER, num);
    }

    /** Handles operators and paranthesis in the expression. */
    private Token handleOperator(char c) {

        try {
            TokenType tokenType = to!TokenType(c);
            return Token(tokenType, to!string(c));
        } catch (ConvException) {
            throw new InvalidCharacter(c, colNum + 1);
        }
    }

    /** Handles getting the entire number. */
    private string getNumber() {
        int start = colNum;
        bool dotFound = getCurrChar() == DOT;

        // For cases where the the number starts with a decimal. If there's no
        // advance(), then the while loop is never entered.
        if (dotFound)
            advance();

        while (!isAtEnd() && isDigit(getCurrChar())) {
            advance();
            if (!isAtEnd() && getCurrChar() == DOT) {
                if (dotFound) {
                    throw new InvalidCharacter(getCurrChar(), colNum);
                }
                dotFound = true;
                advance();
            }
        }

        return to!string(expression[start .. colNum]);

    }

    // ----- Helpers -----
    /** Advances by one character in the expression. */
    private void advance() {
        colNum++;
    }

    /** Returns `True` if the all characters in the expression have been evaluated. */
    private bool isAtEnd() const {
        return colNum >= expression.length;
    }

    /** Gets the current character to be evaluated in the expression. */
    private char getCurrChar() {
        return expression[colNum];
    }

    debug {
        /** Resets the tokenizer with the given expression. */
        void reset(string expression) {
            this.expression = expression;
            this.colNum = 0;
            this.tokens = new Token[0];
        }
    }

}

// ----- TESTS -----
@("Number")
unittest {
    // Only a number
    string number = "1234";
    auto tokenizer = new Tokenizer(number);
    auto tokens = tokenizer.tokenize();
    assert(tokens == [Token(TokenType.NUMBER, number)]);
}

@("Decimal number")
unittest {

    string number = "12.34";
    auto tokenizer = new Tokenizer(number);
    auto tokens = tokenizer.tokenize();
    assert(tokens == [Token(TokenType.NUMBER, number)]);

    number = ".1234";
    tokenizer = new Tokenizer(number);
    tokens = tokenizer.tokenize();
    assert(tokens == [Token(TokenType.NUMBER, number)]);

    number = "1234.";
    tokenizer = new Tokenizer(number);
    tokens = tokenizer.tokenize();
    assert(tokens == [Token(TokenType.NUMBER, number)]);
}

@("Invalid decmial number")
unittest {
    string number = "12.3.4";
    auto tokenizer = new Tokenizer(number);
    assertThrown!InvalidCharacter(tokenizer.tokenize());

    number = "12.34.";
    tokenizer = new Tokenizer(number);
    assertThrown!InvalidCharacter(tokenizer.tokenize());

    number = ".12.34.";
    tokenizer = new Tokenizer(number);
    assertThrown!InvalidCharacter(tokenizer.tokenize());
}

@("Valid expression without spaces")
unittest {
    string expression = "(1+23-90/75*32.23)^2";
    auto tokenizer = new Tokenizer(expression);
    auto expectedTokens = [
        Token(TokenType.LEFT_PARAN, "("),
        Token(TokenType.NUMBER, "1"),
        Token(TokenType.PLUS, "+"),
        Token(TokenType.NUMBER, "23"),
        Token(TokenType.MINUS, "-"),
        Token(TokenType.NUMBER, "90"),
        Token(TokenType.DIVIDE, "/"),
        Token(TokenType.NUMBER, "75"),
        Token(TokenType.MULTIPLY, "*"),
        Token(TokenType.NUMBER, "32.23"),
        Token(TokenType.RIGHT_PARAN, ")"),
        Token(TokenType.POWER, "^"),
        Token(TokenType.NUMBER, "2"),
    ];

    auto actual = tokenizer.tokenize();
    assert(actual == expectedTokens);
}

@("Valid expression with spaces")
unittest {
    string expression = "( 1 + 23 - 90 / 75 * 32.23 ) ^ 2";
    auto tokenizer = new Tokenizer(expression);
    auto expectedTokens = [
        Token(TokenType.LEFT_PARAN, "("),
        Token(TokenType.NUMBER, "1"),
        Token(TokenType.PLUS, "+"),
        Token(TokenType.NUMBER, "23"),
        Token(TokenType.MINUS, "-"),
        Token(TokenType.NUMBER, "90"),
        Token(TokenType.DIVIDE, "/"),
        Token(TokenType.NUMBER, "75"),
        Token(TokenType.MULTIPLY, "*"),
        Token(TokenType.NUMBER, "32.23"),
        Token(TokenType.RIGHT_PARAN, ")"),
        Token(TokenType.POWER, "^"),
        Token(TokenType.NUMBER, "2"),
    ];

    auto actual = tokenizer.tokenize();
    assert(actual == expectedTokens, "Failed with spaces");

    // Random spaces
    expression = "( 1 +23 -90 /75 * 32.23 ) ^2  ";
    tokenizer = new Tokenizer(expression);
    actual = tokenizer.tokenize();
    assert(actual == expectedTokens, "Failed with random spaces");
}

@("Invalid expression")
unittest {
    string expression = "1 + 4.3 % 4";
    auto tokenizer = new Tokenizer(expression);
    assertThrown!InvalidCharacter(tokenizer.tokenize(), "Failed on invalid expression");

    expression = "1 + 4.3. / 4";
    tokenizer = new Tokenizer(expression);
    assertThrown!InvalidCharacter(tokenizer.tokenize(), "Failed on invalid expression");
}
