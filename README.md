# llvm_compiler
Experimental Dart -> LLVM compiler.

# Installation
```bash
pub global activate --source git https://github.com/thosakwe/llvm_compiler.git
```

# Usage
Run `dart2llvm --help` to see usage options.

# Compilation
To compile an object file:
1. Create a Dart program. Ensure it has a `main` entry point.
2. `dart2llvm <filename>.dart | <filename>.obj`. On Unix, pipe to `<filename>.o` instead.

To compile an executable:
1. `dart2llvm <filename>.dart`

You can also forego the whole process, and run JIT-compiled (via `lli`):
1. `dart2llvm --execute filename.dart`