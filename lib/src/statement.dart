import 'package:analyzer/dart/ast/ast.dart';
import 'package:llvm/llvm.dart';
import 'context.dart';
import 'dart_object.dart';
import 'expression.dart';

abstract class StatementCompiler {
  static void compileStatement(
      Statement statement, LlvmBlock block, CompilerContext ctx) {
    if (statement is VariableDeclarationStatement)
      compileVariableDeclaration(statement, block, ctx);
    else if (statement is ReturnStatement)
      compileReturn(statement, block, ctx);
    else if (statement is ExpressionStatement) {
      block.addStatement(ExpressionCompiler.compileExpression(
          statement.expression, block, ctx));
    } else
      throw new UnsupportedError(
          'Cannot compile ${statement.runtimeType}: "${statement.toSource()}".');
  }

  static void compileVariableDeclaration(VariableDeclarationStatement statement,
      LlvmBlock block, CompilerContext ctx) {
    for (var varDecl in statement.variables.variables) {
      if (varDecl.initializer == null)
        throw new UnsupportedError(
            'Variables must have an initializer. Add a value to "${varDecl.toSource()}".');
      else {
        var variable = new LlvmValue(varDecl.name.name);
        block.addStatement(variable.assign(ExpressionCompiler.compileExpression(
            varDecl.initializer, block, ctx)));
        ctx.scope.add(varDecl.name.name,
            value:
                new HybridObject(varDecl.initializer.bestType, variable.type));
      }
    }
  }

  static void compileReturn(
      ReturnStatement statement, LlvmBlock block, CompilerContext ctx) {
    block.addStatement(ExpressionCompiler
        .compileExpression(statement.expression, block, ctx)
        .asReturn());
  }
}
