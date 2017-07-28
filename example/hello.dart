import 'package:llvm_compiler_meta/llvm_compiler_meta.dart';

@extern
external int puts(String message);

int main(int argc, List<String> argv) {
  puts('Hello, LLVM world!');
  return 0;
}
