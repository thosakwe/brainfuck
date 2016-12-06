import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:brainfuck/brainfuck.dart';
import 'package:charcode/charcode.dart';
import 'package:code_builder/code_builder.dart';
import 'package:path/path.dart' as p;

Future<int> main(List<String> args) async {
  try {
    final parser = createParser();
    final results = parser.parse(args);

    if (results['help']) {
      printUsage();
      return exitCode = 1;
    }

    if (results.rest.isEmpty) {
      throw new ArgParserException('No input file(s) provided.');
    }

    for (String filename in results.rest) {
      await compileFile(filename, results);
    }

    return exitCode = 0;
  } catch (e, st) {
    if (e is ArgParserException) {
      stderr.writeln(e.message);
      printUsage();
    } else if (e is BfcException) {
      stderr
        ..writeln('Compiler error: ${e.message}')
        ..writeln('Source index: ${e.index}')
        ..writeln()
        ..writeln(new String.fromCharCodes(e.source));

      final buf = <int>[];

      for (int i = 0; i < e.source.length; i++) {
        if (i == e.index) {
          buf..add($caret)..add($lf);
          break;
        } else {
          buf.add($space);
        }
      }

      stderr.add(buf);
    } else {
      stderr..writeln(e)..writeln(st);
    }

    return exitCode = 1;
  }
}

compileFile(String filename, ArgResults results) async {
  final file = new File(filename);
  final buf = await file.readAsBytes();
  final lib = new Compiler(
          benchmark: results['benchmark'],
          stackSize: int.parse(results['stack-size']))
      .compile(buf);
  final base = p.basenameWithoutExtension(file.path);
  final out = new File.fromUri(file.parent.uri.resolve('$base.dart'));
  await out.writeAsString(prettyToSource(lib.buildAst()));
}

void printUsage() {
  print('usage: bfc [options...] [<filenames>]');
  print('Options:\n');
  print(createParser().usage);
}
