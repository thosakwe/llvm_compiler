import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:symbol_table/symbol_table.dart';

class CompilerContext {
  SymbolTable<DartObject> _scope = new SymbolTable<DartObject>();
  AnalysisContext analysisContext;
  CompilationUnit compilationUnit;

  TypeProvider get typeProvider => analysisContext.typeProvider;

  SymbolTable<DartObject> get scope => _scope;

  void pushScope() {
    _scope = _scope.createChild();
  }

  void popScope() {
    if (_scope.isRoot)
      throw new StateError('Cannot pop root scope');
    else
      _scope = _scope.parent;
  }
}
