import 'package:analyzer/dart/ast/ast.dart';
import 'package:llvm/llvm.dart';
import 'context.dart';
import 'type.dart';

class ExpressionCompiler {
  static LlvmExpression compileExpression(
      Expression expression, LlvmBlock block, CompilerContext ctx) {
    if (expression is SimpleIdentifier)
      return compileSimpleIdentifier(expression, block, ctx);
    else if (expression is Literal)
      return compileLiteral(expression, block, ctx);
    else if (expression is BinaryExpression)
      return compileBinaryExpression(expression, block, ctx);
    else if (expression is MethodInvocation)
      return compileMethodInvocation(expression, block, ctx);
    throw new UnsupportedError(
        'Cannot compile ${expression.runtimeType}: "${expression.toSource()}"');
  }

  static LlvmExpression compileLiteral(
      Literal expression, LlvmBlock block, CompilerContext ctx) {
    if (expression is IntegerLiteral) {
      return Literals.i32(expression.value);
    } else if (expression is DoubleLiteral) {
      return Literals.$double(expression.value);
    } else if (expression is BooleanLiteral) {
      return Literals.$bool(expression.value);
    } else if (expression is SimpleStringLiteral) {
      var str = Literals.string(expression.stringValue);
      var name = ctx.uniqueName('str');
      ctx.module.constants.add(new LlvmConstant(name, str));

      var ref = new LlvmValue.reference(name, str.type, constant: true);
      return ref[Literals.i8(0)];
    } else {
      throw new UnsupportedError(
          'Cannot compile ${expression.runtimeType}: "${expression.toSource()}"');
    }
  }

  static LlvmExpression compileSimpleIdentifier(
      SimpleIdentifier expression, LlvmBlock block, CompilerContext ctx) {
    // Infer from context
    var symbol = ctx.scope.resolve(expression.name);

    if (symbol == null)
      throw new StateError(
          'The name "${expression.name}" does not exist in this context.');
    else {
      var type = TypeCompiler.compileType(symbol.value.dartType, ctx);
      return new LlvmValue.reference(expression.name, type);
    }
  }

  static LlvmExpression compileBinaryExpression(
      BinaryExpression expression, LlvmBlock block, CompilerContext ctx) {
    // TODO: All operators
    Instruction operator;

    switch (expression.operator.lexeme) {
      case '*':
        operator = Instruction.mul;
        break;
      case '/':
        operator = Instruction.div;
        break;
      case '+':
        operator = Instruction.add;
        break;
      case '-':
        operator = Instruction.sub;
        break;
    }

    if (operator == null)
      throw new UnsupportedError(
          'Unsupported binary operator: "${expression.operator.lexeme}"');

    var l = compileExpression(expression.leftOperand, block, ctx);
    var r = compileExpression(expression.rightOperand, block, ctx);
    return new LlvmBinaryExpression(operator, l, r);
  }

  static LlvmExpression compileMethodInvocation(
      MethodInvocation expression, LlvmBlock block, CompilerContext ctx) {
    // TODO: Figure out how to compile this???
    LlvmExpression target;

    if (expression.realTarget != null || expression.target != null)
      target = compileExpression(
          expression.realTarget ?? expression.target, block, ctx);
    else {
      var symbol = ctx.scope.resolve(expression.methodName.name);

      if (symbol == null)
        throw 'No function "${expression.methodName.name}" exists in this context.';

      if (symbol.value.function == null &&
          symbol.value.llvmType is! LlvmFunctionType)
        throw '"${expression.methodName.name}" is not a function.';

      target = new LlvmValue.reference(
          expression.methodName.name, symbol.value.llvmType);
    }

    List<LlvmExpression> args = [];

    for (var arg in expression.argumentList.arguments) {
      var expr = compileExpression(arg, block, ctx);

      if (expr.canBeFunctionArgument)
        args.add(expr);
      else {
        var name = ctx.uniqueName('tmp');
        var value = new LlvmValue(name);
        block.addStatement(value.assign(expr));
        args.add(value);
      }
    }

    return target.call(args);
  }
}
