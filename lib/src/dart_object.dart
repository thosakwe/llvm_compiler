import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';

class DartObjectImpl extends DartObject {
  final DartType _type;

  DartObjectImpl(this._type);

  @override
  DartObject getField(String name) {
    // TODO: implement getField
    return null;
  }

  @override
  bool get hasKnownValue => false;

  @override
  bool get isNull => false;

  @override
  ParameterizedType get type => _type;

  @override
  bool toBoolValue() => null;

  @override
  double toDoubleValue() => null;

  @override
  int toIntValue() => null;

  @override
  List<DartObject> toListValue() => null;

  @override
  Map<DartObject, DartObject> toMapValue() => null;

  @override
  String toStringValue() => null;

  @override
  String toSymbolValue() => null;

  @override
  DartType toTypeValue() => null;
}
