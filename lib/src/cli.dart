import 'package:args/args.dart';

ArgParser createParser() {
  return new ArgParser(allowTrailingOptions: true)
    ..addFlag('benchmark',
        help: 'Adds benchmarking code to the output.', defaultsTo: true)
    ..addFlag('help',
        abbr: 'h', help: 'Print this help information.', negatable: false)
    ..addOption('stack-size',
        abbr: 's', help: 'Sets the stack size.', defaultsTo: '255');
}
