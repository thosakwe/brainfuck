import 'package:charcode/charcode.dart';
import 'package:code_builder/code_builder.dart';
import 'bfc_exception.dart';

class Compiler {
  /// Keep track of pointer internally, for optimization's sake.
  int _ptr = 0;
  final Map<int, int> _stack = {};

  final bool benchmark;
  final int stackSize;

  Compiler({this.benchmark: true, this.stackSize: 255});

  LibraryBuilder compile(List<int> data) {
    return new LibraryBuilder()
      ..addDirective(new ImportBuilder('dart:io'))
      ..addMember(buildMain(data));
  }

  MethodBuilder buildMain(List<int> data) {
    final builder = new MethodBuilder('main');

    if (benchmark) {
      builder.addStatements(setUpBenchmarking());
    }

    // builder.addStatement(createStack());

    for (int i = 0; i < data.length; i++) {
      final stmt = compileInstruction(builder, data, i, data[i]);

      if (stmt != null && stmt != false) {
        builder.addStatement(stmt);
      } else if (stmt == false) {
        break;
      }
    }

    builder.addStatement(reference('stdout').invoke('writeln', []));

    if (benchmark) {
      builder.addStatements(tearDownBenchmarking());
    }

    return builder;
  }

  StatementBuilder createStack() {
    final type =
        new TypeBuilder('List', genericTypes: [new TypeBuilder('int')]);
    return varFinal('stack',
        type: type,
        value:
            type.namedNewInstance('filled', [literal(stackSize), literal(0)]));
  }

  compileInstruction(MethodBuilder builder, List<int> data, int i, int cmd) {
    if (cmd == $gt) {
      if (_ptr < stackSize)
        _ptr++;
      else
        throw new BfcException(
            i, 'Cannot exceed stack size of $stackSize.', data);
    }

    if (cmd == $lt) {
      if (_ptr > 0)
        _ptr--;
      else
        throw new BfcException(
            i, 'Memory pointer cannot go below 0. Current index: $_ptr', data);
    }

    if (cmd == $plus) {
      set(_ptr, get(_ptr) + 1);
    }

    if (cmd == $minus) {
      set(_ptr, get(_ptr) - 1);
    }

    if (cmd == $dot) {
      return reference('stdout').invoke('write', [
        new TypeBuilder('String')
            .namedNewInstance('fromCharCode', [literal(get(_ptr))])
      ]);
    }

    if (cmd == $comma) {
      // Todo: Make this async...
      // return set(_ptr, );
      throw new BfcException(i, 'User input is not yet supported.', data);
    }

    if (cmd == $lbracket) {
      if (get(_ptr) == 0) {
        for (int j = i + 1; j < data.length; j++) {
          final ch = data[j];

          if (ch == $rbracket) {
            return jumpTo(builder, j, data);
          }
        }

        throw new BfcException(i, "Unmatched '['.", data);
      }
    }

    if (cmd == $rbracket) {
      if (get(_ptr) != 0) {
        for (int j = i - 1; j >= 0; j--) {
          final ch = data[j];

          if (ch == $lbracket) {
            return jumpTo(builder, j, data);
          }
        }

        throw new BfcException(i, "Unmatched ']'.", data);
      }
    }

    return null;
  }

  List<StatementBuilder> setUpBenchmarking() {
    return [
      varFinal('sw', value: new TypeBuilder('Stopwatch').newInstance([])),
      reference('sw').invoke('start', [])
    ];
  }

  List<StatementBuilder> tearDownBenchmarking() {
    return [
      reference('sw').invoke('stop', []),
      reference('print')
          .call([literal(r'Elapsed time: ${sw.elapsedMilliseconds} ms')])
    ];
  }

  jumpTo(MethodBuilder builder, int j, List<int> data) {
    for (int i = j + 1; i < data.length; i++) {
      final stmt = compileInstruction(builder, data, i, data[i]);

      if (stmt != null && stmt != false) {
        builder.addStatement(stmt);
      } else if (stmt == false) {
        break;
      }
    }

    return false;
  }

  int get(int i) {
    return _stack.containsKey(i) ? _stack[i] : _stack[i] = 0;
  }

  void set(int i, int value) {
    _stack[i] = value;
  }
}
