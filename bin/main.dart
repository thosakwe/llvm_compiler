import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:file/local.dart' show LocalFileSystem;
import 'package:indenting_buffer/indenting_buffer.dart';
import 'package:llvm/llvm.dart';
import 'package:llvm_compiler/llvm_compiler.dart';
import 'package:platform/platform.dart' show LocalPlatform;
import 'package:process/process.dart';

final ArgParser argParser = new ArgParser(allowTrailingOptions: true)
  ..addFlag('emit-asm', help: 'Emit Assembly code.', negatable: false)
  ..addFlag('emit-llvm',
      help: 'Emit LLVM IR, instead of machine oode.', negatable: false)
  ..addFlag('execute',
      abbr: 'x',
      help: 'JIT-compile the generated LLVM IR, and run it.',
      negatable: false)
  ..addFlag('freestanding',
      help: 'Emit a plain object file, without linking in the Dart runtime.',
      negatable: false)
  ..addFlag('help',
      abbr: 'h', help: 'Print this help information.', negatable: false)
  ..addFlag('optimize',
      help: 'Optimizes LLVM IR before compilation into machine code.',
      defaultsTo: true)
  ..addFlag('verbose',
      abbr: 'v', help: 'Print verbose output.', negatable: false)
  ..addOption('link',
      abbr: 'l',
      allowMultiple: true,
      help: 'Specifiy additional library files to link against.')
  ..addOption('out', abbr: 'o', help: 'Specifies an output filename.');

main(List<String> args) async {
  try {
    var result = argParser.parse(args);

    if (result['help']) {
      showHelp(stdout
        ..writeln(
            'dart2llvm: An experimental Dart -> LLVM compiler © Tobe Osakwe 2017')
        ..writeln());
    } else if (result.rest.isEmpty) {
      throw 'no input file';
    } else {
      var file = new File(result.rest.first);
      var ctx = await buildContext(file);
      var mod = LlvmCompiler.compileCompilationUnit(ctx.compilationUnit, ctx);

      IOSink sink = stdout;
      File f;

      if (result.wasParsed('out')) {
        f = new File(result['out']);
        await f.create(recursive: true);
        sink = f.openWrite();
      }

      var toolChain = const LlvmToolchain(const LocalFileSystem(),
          const LocalPlatform(), const LocalProcessManager());
      var buf = new IndentingBuffer();
      mod.compile(buf);
      var ir = buf.toString();

      bool shouldPipe = true;
      Stream<List<int>> outputStream =
          new Stream<List<int>>.fromIterable([ir.codeUnits]);

      if (result['optimize']) {
        outputStream = toolChain.optimizeIR(outputStream);
      }

      if (!result['emit-llvm']) {
        if (result['emit-asm']) {
          outputStream = toolChain.compileIRToAssemblyCode(outputStream);
        } else {
          if (result['execute']) {
            if (sink != stdout) {
              await sink.close();
              await f?.delete();
            }

            await stdout.addStream(
                toolChain.executeIR(outputStream, result.rest.skip(1)));
            return;
          }

          outputStream = toolChain.compileIRToMachineCode(outputStream);

          if (!result['freestanding']) {
            var dartExecutable = new File(Platform.resolvedExecutable);
            var dartLib =
                new File.fromUri(dartExecutable.parent.uri.resolve('dart.lib'))
                    .absolute
                    .path;

            shouldPipe = false;

            if (sink != stdout) {
              await sink.close();
              await f?.delete();
            }

            List<String> include = [dartLib];
            include.addAll(result['link'] ?? []);

            if (!result.wasParsed('out')) {
              await outputStream.toList();

              if (sink != stdout) {
                await sink.close();
                await f?.delete();
              }

              throw 'You must provide an output path when compiling to an executable.';
            }

            await toolChain.linkToExecutable(outputStream,
                includeLibraries: include, outputPath: result['out']);
          }
        }
      }

      if (shouldPipe) await outputStream.pipe(sink);
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
