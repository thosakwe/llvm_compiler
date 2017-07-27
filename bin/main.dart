import 'dart:io';
import 'package:args/args.dart';
import 'package:indenting_buffer/indenting_buffer.dart';
import 'package:llvm/llvm.dart';
import 'package:llvm_compiler/llvm_compiler.dart';
import 'package:process/process.dart';

final ArgParser argParser = new ArgParser(allowTrailingOptions: true)
  ..addFlag('emit-llvm',
      help: 'Emit LLVM IR, instead of machine oode.', negatable: false)
  ..addFlag('help',
      abbr: 'h', help: 'Print this help information.', negatable: false)
  ..addFlag('verbose',
      abbr: 'v', help: 'Print verbose output.', negatable: false)
  ..addOption('out', abbr: 'o', help: 'Specifies an output filename.');

main(List<String> args) async {
  try {
    var result = argParser.parse(args);

    if (result['help']) {
      showHelp(stdout
        ..writeln('dart2llvm: An experimental Dart -> LLVM compiler')
        ..writeln());
    } else if (result.rest.isEmpty) {
      throw 'no input file';
    } else {
      var file = new File(result.rest.first);
      var ctx = await buildContext(file);
      var mod = LlvmCompiler.compileCompilationUnit(ctx.compilationUnit, ctx);

      IOSink sink = stdout;

      if (result.wasParsed('out')) {
        var f = new File(result['out']);
        await f.create(recursive: true);
        sink = f.openWrite();
      }

      var buf = new IndentingBuffer();
      mod.compile(buf);

      if (result['emit-llvm']) {
        var ir = buf.toString();

        sink.writeln(ir);
      } else {
        var toolChain = new LlvmToolchain(const LocalProcessManager());
        var ir = await toolChain.compiler.compile(buf.toString().codeUnits);
        await sink.addStream(ir);
      }

      await sink.close();
    }
  } on ArgParserException catch (e) {
    stderr.writeln('fatal error: ${e.message}');
    showHelp(stderr);
    exitCode = 1;
  } catch (e, st) {
    stderr.writeln('fatal error: $e');
    if (args.contains('-v') || args.contains('--verbose')) stderr.writeln(st);
    exitCode = 1;
  }
}

void showHelp(IOSink sink) {
  sink
    ..writeln('usage: dart2llvm [options] <input-file>')
    ..writeln('Options:')
    ..writeln(argParser.usage);
}
