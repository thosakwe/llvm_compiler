import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:llvm/llvm.dart';
import 'context.dart';
import 'dart_object.dart';
import 'statement.dart';
import 'type.dart';

class LlvmCompiler {
  static LlvmModule compileCompilationUnit(
      CompilationUnit compilationUnit, CompilerContext ctx) {
    var mod = ctx.module = new LlvmModule(
        compilationUnit.element.library?.name ??
            compilationUnit.element.name ??
            'compiled_dart');

    for (var decl in compilationUnit.declarations) {
      if (decl is! FunctionDeclaration)
        throw 'Only top-level functions are supported, not ${decl.runtimeType}. Remove "${decl.toSource()}".';

      mod.functions.add(compileFunction(decl, mod, ctx));
    }

    return mod;
  }

  static LlvmFunction compileFunction(
      FunctionDeclaration function, LlvmModule module, CompilerContext ctx) {
    var type = TypeCompiler.compileType(function.returnType.type, ctx);
    LlvmFunction fn;

    if (function.externalKeyword == null)
      fn = new LlvmFunction(function.name.name, returnType: type);
    else
      fn = new LlvmExternalFunction(function.name.name, returnType: type);

    var functionType = new LlvmFunctionType(function.name.name, type);

    ctx.scope.add(function.name.name,
        value: new HybridObject(ctx.typeProvider.functionType, functionType,
            function: fn));

    ctx.pushScope();

    for (var param in function.element.parameters) {
      var t = TypeCompiler.compileType(param.type, ctx);
      fn.parameters.add(new LlvmParameter(param.name, t));
      functionType.parameters.add(t);
      ctx.scope.add(param.name, value: new HybridObject(param.type, t));
    }

    if (function.externalKeyword == null) {
      var fnExpr =
          function.childEntities.firstWhere((e) => e is FunctionExpression);
      fn.blocks.add(compileFunctionExpression(fnExpr, ctx));
    }

    for (var block in fn.blocks) {
      block.addStatement(LlvmStatement.returnVoid);
    }

    ctx.popScope();
    return fn;
  }

  static LlvmBasicBlock compileFunctionExpression(
      FunctionExpression function, CompilerContext ctx) {
    var block = new LlvmBasicBlock('entry');

    for (var entity in function.body.childEntities) {
      if (entity is! Statement &&
          !(entity is SimpleToken && entity.lexeme == ';'))
        throw 'Only statements are supported in functions. Unexpected ${entity.runtimeType} $entity.';
      else if (entity is Block) {
        for (var statement in entity.statements) {
          StatementCompiler.compileStatement(statement, block, ctx);
        }
      } else if (entity is Statement)
        StatementCompiler.compileStatement(entity, block, ctx);
    }

    return block;
  }
}
