import 'package:analyzer/dart/element/type.dart';
import 'package:llvm/llvm.dart';
import 'context.dart';

abstract class TypeCompiler {
  static LlvmType compileType(DartType type, CompilerContext ctx) {
    if (type.isAssignableTo(ctx.typeProvider.listType) ||
        (type is InterfaceType && type.name == 'List')) {
      if (type is! InterfaceType ||
          (type is InterfaceType && type.typeArguments.isEmpty))
        throw new UnsupportedError(
            'Lists can only be compiled if they hold a type argument.');
      else {
        var innerType = (type as InterfaceType).typeArguments.first;
        return compileType(innerType, ctx).pointer();
      }
    } else if (type.isSubtypeOf(ctx.typeProvider.intType))
      return LlvmType.i32;
    else if (type.isSubtypeOf(ctx.typeProvider.doubleType))
      return LlvmType.double;
    else if (type.isSubtypeOf(ctx.typeProvider.boolType))
      return LlvmType.i1;
    else if (type.isSubtypeOf(ctx.typeProvider.stringType))
      return LlvmType.i8.pointer();
    else if (type.name == 'void')
      return LlvmType.$void;
    else
      throw new UnsupportedError('Cannot compile type "${type.name}" yet.');
  }
}
