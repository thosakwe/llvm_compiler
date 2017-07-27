import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:llvm/llvm.dart';
import 'context.dart';
import 'dart_object.dart';
import 'expression.dart';
import 'statement.dart';
import 'type.dart';

class LlvmCompiler {
  static LlvmModule compileCompilationUnit(
      CompilationUnit compilationUnit, CompilerContext ctx) {
    var mod = new LlvmModule(compilationUnit.element.library?.name ??
        compilationUnit.element.name ??
        'compiled_dart');

    for (var decl in compilationUnit.declarations) {
      if (decl is! FunctionDeclaration)
        throw 'Only top-level functions are supported, not ${decl.runtimeType}. Remove "${decl.toSource()}".';
      mod.functions.add(compileFunction(decl, ctx));
    }

    return mod;
  }

  static LlvmFunction compileFunction(
      FunctionDeclaration function, CompilerContext ctx) {
    var type = TypeCompiler.compileType(function.returnType.type, ctx);
    var fn = new LlvmFunction(function.name.name, returnType: type);

    ctx.pushScope();

    for (var param in function.element.parameters) {
      var t = TypeCompiler.compileType(param.type, ctx);
      fn.parameters.add(new LlvmParameter(param.name, t));
      ctx.scope.add(param.name, value: new DartObjectImpl(param.type));
    }

    var fnExpr =
        function.childEntities.firstWhere((e) => e is FunctionExpression);
    fn.blocks.add(compileFunctionExpression(fnExpr, ctx));

    ctx.popScope();
    return fn;
  }

  static LlvmBasicBlock compileFunctionExpression(
      FunctionExpression function, CompilerContext ctx) {
    var block = new LlvmBasicBlock('entry');

    for (var entity in function.body.childEntities) {
      if (entity is! Statement)
        throw 'Only statements are supported in functions. Unexpected $entity.';
      else if (entity is Block) {
        for (var statement in entity.statements) {
          StatementCompiler.compileStatement(statement, block, ctx);
        }
      } else
        StatementCompiler.compileStatement(entity, block, ctx);
    }

    return block;
  }
}