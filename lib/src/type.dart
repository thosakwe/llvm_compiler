import 'package:analyzer/dart/element/type.dart';
import 'package:llvm/llvm.dart';
import 'context.dart';

abstract class TypeCompiler {
  static LlvmType compileType(DartType type, CompilerContext ctx) {
    if (type.isSubtypeOf(ctx.typeProvider.intType))
      return LlvmType.i32;

    throw new UnsupportedError('Cannot compile type "${type.name}" yet.');
  }
}