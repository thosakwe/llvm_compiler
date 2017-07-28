import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:llvm/llvm.dart';
import 'package:symbol_table/symbol_table.dart';
import 'dart_object.dart';

class CompilerContext {
  final Map<String, int> _ids = {};
  SymbolTable<HybridObject> _scope = new SymbolTable<HybridObject>();
  AnalysisContext analysisContext;
  CompilationUnit compilationUnit;
  LlvmModule module;

  TypeProvider get typeProvider => analysisContext.typeProvider;

  SymbolTable<HybridObject> get scope => _scope;

  String uniqueName(String prefix) {
    var n = _ids.putIfAbsent(prefix, () => 0);
    _ids[prefix]++;
    return '$prefix$n';
  }

  void pushScope() {
    _scope = _scope.createChild();
  }

  void popScope() {
    if (_scope.isRoot)
      throw new StateError('Cannot pop root scope');
    else
      _scope = _scope.parent;
    // TODO: Trigger GC
  }
}
