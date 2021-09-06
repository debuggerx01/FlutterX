import 'dart:io';
import 'path_utils.dart';
import 'parse_arguments.dart';
import 'expressions/expressions.dart';
import 'flavors.dart';

const BLACK_FILE_EXT = [
  'md',
];

final _ctx = {
  'debug': 'debug',
  'release': 'release',
  'profile': 'profile',
  'default': 'default',
};

String? exp;
late String mode;
late String flavor;
late bool isReplace;

enum STATE {
  none,
  notMatch,
  caching,
  replace,
  inDefault,
}

void main(List<String> arguments) {
  print("Running default pre_script.");
  var args = parse(arguments);
  mode = args.mode;
  flavor = args.flavor;
  isReplace = args.isReplaceMode;

  if (!FLAVORS.contains(flavor) && flavor != 'default')
    throw Exception('Undefined flavor !!!');

  _ctx.addEntries(FLAVORS.map((e) => MapEntry(e, e)));

  _ctx.addAll({
    'mode': mode,
    'flavor': flavor,
  });

  var rootDir = Directory('./');
  rootDir.listSync().forEach(walkPath);
}

File? file;
StringBuffer sb = StringBuffer();
StringBuffer tmp = StringBuffer();
STATE state = STATE.none;
RegExp re = RegExp(r'// #\{\{(.+)\}\}');

Match? ma;
bool modified = false;

const evaluator = const ExpressionEvaluator();
late List<String> lines;

// vars for replace mode
int currentLineIndex = 0;
List<ReplaceOperation> operations = [];
List<ReplaceOperation> tempOperations = [];
List<ReplaceOperation> currentTempOperations = [];

final _commentReg = RegExp(' *\/\/');

var lastIndent = -1;

void walkPath(FileSystemEntity path) {
  var stat = path.statSync();
  if (stat.type == FileSystemEntityType.directory) {
    Directory(path.path)
        .listSync()
        .where((f) => !PathUtils.baseName(f).startsWith('.'))
        .forEach(walkPath);
  } else if (stat.type == FileSystemEntityType.file &&
      BLACK_FILE_EXT.indexWhere((ele) => path.path.endsWith(ele)) < 0) {
    file = File(path.path);
    sb.clear();
    modified = false;
    state = STATE.none;
    if (isReplace) {
      currentLineIndex = 0;
      operations.clear();
      tempOperations.clear();
      currentTempOperations.clear();
    }
    try {
      lines = file!.readAsLinesSync();
      lines.forEach((line) {
        currentLineIndex++;
        ma = re.firstMatch(line);
        if (ma != null) {
          lastIndent = line.indexOf('// #{{');
          modified = true;
          exp = ma!.group(1);
          if (exp == "default") {
            if (isReplace) {
              if (currentTempOperations.isNotEmpty &&
                  !currentTempOperations.first.commented)
                tempOperations.forEach((ele) => ele.commented = true);
              tempOperations.addAll(currentTempOperations);
              currentTempOperations.clear();
            }

            // 默认代码块开始
            if (tmp.isNotEmpty) {
              sb.write(tmp);
              print([
                "${file!.path} modified" + '\n',
                "-" * 80 + '\n',
                tmp.toString(),
                "-" * 80 + '\n',
              ].join());
              state = STATE.replace;
            } else {
              state = STATE.inDefault;
            }
          } else if (exp == "end") {
            // 默认代码块结束
            state = STATE.none;
            if (isReplace) {
              if (tmp.isEmpty) {
                // 说明匹配到了默认代码块，应该将之前的代码全注释掉
                tempOperations.forEach((ele) => ele.commented = true);
              } else {
                // 之前有匹配到的代码块，应该将默认代码块注释掉
                currentTempOperations.forEach((ele) => ele.commented = true);
              }
              tempOperations.addAll(currentTempOperations);
              operations.addAll(tempOperations);
              tempOperations.clear();
              currentTempOperations.clear();
            }
            tmp.clear();
          } else {
            if (evaluator.eval(Expression.parse(exp!), _ctx)) {
              // 匹配到
              tmp.clear();
              state = STATE.caching;
            } else {
              state = STATE.notMatch;
            }
            if (isReplace) {
              if (state == STATE.caching) {
                tempOperations.forEach((ele) => ele.commented = true);
                currentTempOperations.forEach((ele) => ele.commented = true);
              }
              tempOperations.addAll(currentTempOperations);
              currentTempOperations.clear();
            }
          }
        } else {
          // none状态时直接将line写入sb
          if ([STATE.none, STATE.inDefault].contains(state)) {
            sb.writeln(line);
          }
          // 缓存中状态，将用于替换的内容移除注释后写入缓存
          else if (state == STATE.caching)
            tmp.writeln(line.replaceFirst('// ', ''));
          // 这样就跳过了没有匹配上的替换代码块和默认内容

          if (isReplace &&
              [STATE.notMatch, STATE.caching, STATE.replace, STATE.inDefault]
                  .contains(state)) {
            currentTempOperations.add(ReplaceOperation(
                currentLineIndex, lastIndent, state == STATE.notMatch));
          }
        }
      });
      if (modified) {
        if (isReplace) {
          operations.forEach((operation) {
            if (operation.commented &&
                !lines[operation.lineNumber - 1].startsWith(_commentReg) &&
                lines[operation.lineNumber - 1].trim().length > 0) {
              lines[operation.lineNumber - 1] =
                  '${' ' * operation.indent}// ${lines[operation.lineNumber - 1].substring(operation.indent)}';
            } else if (!operation.commented &&
                lines[operation.lineNumber - 1].startsWith(_commentReg))
              lines[operation.lineNumber - 1] =
                  lines[operation.lineNumber - 1].replaceFirst('// ', '');
          });
          file!.deleteSync();
          File(path.path)
              .writeAsStringSync(lines.join('\n') + '\n', flush: true);
          print("${file!.path} modified");
        } else {
          file!.renameSync(path.path + '.bak');
          File(path.path).writeAsStringSync(sb.toString(), flush: true);
        }
      }
    } catch (e) {
      if (!(e is FileSystemException)) {
        rethrow;
      }
    }
  }
}

class ReplaceOperation {
  int lineNumber;
  int indent;
  bool commented;

  ReplaceOperation(this.lineNumber, this.indent, this.commented);
}
