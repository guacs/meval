module expr;
import enums : TokenType;
import tokenizer : Token;
import std.format;
import std.conv;
import exceptions : DivideByZero;

import std.sumtype;

version (unittest) {
    import std.exception;
}

class Expression {
    this() {
    }

    float evaluate() {
        throw new Exception("invalid");
    }

    const {

        override string toString() {
            // This should never be reached.
            return "Expression";
        }

        override bool opEquals(Object o) {
            // This would only be called if the LHS and RHS are 
            // of different types.
            return false;
        }
    }

}

class Number : Expression {
    float number;

    this(float num) {
        this.number = num;
    }

    override float evaluate() {
        return this.number;
    }

    const {
        override bool opEquals(Object o) {

            return this.number == (cast(Number) o).number;

        }

        override string toString() {
            return to!string(this.number);
        }
    }
}

/** A binary expression.

For example, "1 + 2" is a binary expression.
*/
class Binary : Expression {
    Expression leftOperand;
    Expression rightOperand;
    Token operator;

    this(Expression leftOperand, Expression rightOperand, Token operator) {
        this.leftOperand = leftOperand;
        this.rightOperand = rightOperand;
        this.operator = operator;
    }

    override float evaluate() {

        float left = this.leftOperand.evaluate();
        float right = this.rightOperand.evaluate();

        switch (operator.tokenType) {
            case TokenType.PLUS:
                return left + right;
            case TokenType.MINUS:
                return left - right;
            case TokenType.MULTIPLY:
                return left * right;
            case TokenType.POWER:
                import std.math : pow;

                return pow(left, cast(int) right);
            case TokenType.DIVIDE:
                if (right == 0) {
                    throw new DivideByZero();
                }
                return left / right;
            default:
                assert(0);
        }
    }

    const {

        override bool opEquals(Object o) {

            auto castIntoBinary = cast(Binary) o;

            return (
                this.leftOperand == castIntoBinary.leftOperand &&
                    this.rightOperand == castIntoBinary.rightOperand &&
                    this.operator == castIntoBinary.operator
            );

        }

        override string toString() {

            return format("%s %s %s", leftOperand, operator.value, rightOperand);
        }
    }
}

/** A unary expression.

For example, "-1" is a unary expression.*/
class Unary : Expression {
    Expression operand;
    Token operator;

    this(Expression operand, Token operator) {
        this.operand = operand;
        this.operator = operator;
    }

    override float evaluate() {
        switch (operator.tokenType) {
            case TokenType.PLUS:
                return operand.evaluate();
            case TokenType.MINUS:
                return -1 * operand.evaluate();
            default:
                assert(0);
        }
    }

    const {

        override bool opEquals(Object o) {

            auto castIntoUnary = cast(Unary) o;

            return (
                this.operand == castIntoUnary.operand &&
                    this.operator == castIntoUnary.operator
            );

        }

        override string toString() {
            return format("%s %s", operator.value, operand);
        }
    }
}

/** A grouped expression.

For example, "(1 + 2)" is a grouped expression.*/
class Group : Expression {
    Expression expr;

    this(Expression expr) {
        this.expr = expr;
    }

    override float evaluate() {
        return expr.evaluate();
    }

    const {

        override bool opEquals(Object o) {
            return this.expr == (cast(Group) o).expr;
        }

        override string toString() {
            return format("(%s)", to!string(expr));
        }
    }
}

// ----- Tests -----

@("Unary")
unittest {

    // Setup
    auto oneNumber = new Number(1);
    auto minusToken = Token(TokenType.MINUS, "-");
    auto plusToken = Token(TokenType.PLUS, "+");

    // +1
    auto unary = new Unary(oneNumber, plusToken);
    assert(unary.evaluate() == 1);

    // -1
    unary = new Unary(oneNumber, minusToken);
    assert(unary.evaluate() == -1);
}

@("Binary")
unittest {

    // Setup
    auto zeroNumber = new Number(0);
    auto oneNumber = new Number(1);
    auto twoNumber = new Number(2);
    auto minusToken = Token(TokenType.MINUS, "-");
    auto plusToken = Token(TokenType.PLUS, "+");
    auto multiplyToken = Token(TokenType.MULTIPLY, "*");
    auto divideToken = Token(TokenType.DIVIDE, "/");

    // 1 + 2
    auto binary = new Binary(oneNumber, twoNumber, plusToken);
    assert(binary.evaluate() == 3);

    // 1 - 2
    binary = new Binary(oneNumber, twoNumber, minusToken);
    assert(binary.evaluate() == -1);

    // 1 * 2
    binary = new Binary(oneNumber, twoNumber, multiplyToken);
    assert(binary.evaluate() == 2);

    // 1 / 2
    binary = new Binary(oneNumber, twoNumber, divideToken);
    assert(binary.evaluate() == 0.5);

    // 1 / 0
    binary = new Binary(oneNumber, zeroNumber, divideToken);
    assertThrown!DivideByZero(binary.evaluate());
}

@("Group")
unittest {
    // Setup
    auto plusToken = Token(TokenType.PLUS, "+");
    auto minusToken = Token(TokenType.MINUS, "-");
    auto left = new Number(1);
    auto right = new Number(2);

    // (1 + 2)
    auto group = new Group(new Binary(left, right, plusToken));
    assert(group.evaluate() == 3);

    // (1 + (1 - 2))
    group = new Group(
        new Binary(
            left,
            new Group(
            new Binary(left, right, minusToken)
        ),
        plusToken)
    );
    assert(group.evaluate() == 0);
}
