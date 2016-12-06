import 'dart:io';
import 'bfc.dart' as bfc;

main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('usage: bf <name>');
    exitCode = 1;
    return;
  }

  final name = args.first;
  int code = await bfc.main(['$name.bf']);

  if (code == 0) {
    final p = await Process.start(Platform.executable, ['$name.dart']);
    p.stdout.pipe(stdout);
    p.stderr.pipe(stderr);
    code = await p.exitCode;
  }

  final file = new File('$name.dart');

  if (await file.exists()) {
    await file.delete();
  }

  exitCode = code;
}
