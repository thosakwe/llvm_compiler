import 'package:analyzer/dart/element/type.dart';
import 'package:llvm/llvm.dart';

class HybridObject {
  final DartType dartType;
  final LlvmType llvmType;
  final LlvmFunction function;

  HybridObject(this.dartType, this.llvmType, {this.function});
}
