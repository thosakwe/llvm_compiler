import 'package:analyzer/dart/ast/ast.dart';
import 'package:llvm/llvm.dart';
import 'context.dart';
import 'type.dart';

class ExpressionCompiler {
  static LlvmExpression compileExpression(Expression expression, LlvmBlock block, CompilerContext ctx) {
    if (expression is SimpleIdentifier)
      return compileSimpleIdentifier(expression, block, ctx);
    else if (expression is BinaryExpression)
      return compileBinaryExpression(expression, block, ctx);
    throw new UnsupportedError('Cannot compile ${expression.runtimeType}: "${expression.toSource()}"');
  }

  static LlvmExpression compileSimpleIdentifier(SimpleIdentifier expression, LlvmBlock block, CompilerContext ctx) {
    // Infer from context
    var symbol = ctx.scope.resolve(expression.name);

    if (symbol == null)
      throw new StateError('The name "${expression.name}" does not exist in this context.');
    else {
      var type = TypeCompiler.compileType(symbol.value.type, ctx);
      return new LlvmValue.reference(expression.name, type);
    }
  }

  static LlvmExpression compileBinaryExpression(BinaryExpression expression, LlvmBlock block, CompilerContext ctx) {
    // TODO: All operators
    Instruction operator;

    switch (expression.operator.lexeme) {
      case '+':
        operator = Instruction.add;
        break;
      case '*':
        operator = Instruction.mul;
        break;
    }

    if (operator == null)
      throw new UnsupportedError('Unsupported binary operator: "${expression.operator.lexeme}"');

    var l = compileExpression(expression.leftOperand, block, ctx);
    var r = compileExpression(expression.rightOperand, block, ctx);
    return new LlvmBinaryExpression(operator, l, r);
  }
}