import 'dart:io';
import 'parse_arguments.dart';
import 'expressions/expressions.dart';

String? exp;
late String mode;
late String flavor;

enum STATE {
  none,
  notMatch,
  caching,
  replace,
}

void main(List<String> arguments) {
  print("Running default pre_script.");
  var args = parse(arguments);
  mode = args.mode;
  flavor = args.flavor;

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

void walkPath(FileSystemEntity path) {
  var stat = path.statSync();
  if (stat.type == FileSystemEntityType.directory) {
    Directory(path.path).listSync().forEach(walkPath);
  } else if (stat.type == FileSystemEntityType.file) {
    file = File(path.path);
    sb.clear();
    modified = false;
    try {
      file!.readAsLinesSync().forEach((line) {
        ma = re.firstMatch(line);
        if (ma != null) {
          modified = true;
          exp = ma!.group(1);
          if (exp == "default") {
            // 默认代码块开始
            if (tmp.isNotEmpty) {
              sb.write(tmp);
              print([
                "${file!.path} modified",
                "-" * 80,
                tmp.toString(),
                "-" * 80,
              ].join("\n"));
              state = STATE.replace;
            } else {
              state = STATE.none;
            }
          } else if (exp == "end") {
            // 默认代码块结束
            state = STATE.none;
            tmp.clear();
          } else {
            if (evaluator.eval(
                Expression.parse(exp!), {'mode': mode, 'flavor': flavor})) {
              // 匹配到
              tmp.clear();
              state = STATE.caching;
            } else {
              state = STATE.notMatch;
            }
          }
        } else {
          // none状态时直接将line写入sb
          if (state == STATE.none) {
            sb.writeln(line);
          }
          // 缓存中状态，将用于替换的内容移除注释后写入缓存
          else if (state == STATE.caching)
            tmp.writeln(line.replaceFirst('// ', ''));
          // 这样就跳过了没有匹配上的替换代码块和默认内容
        }
      });
      if (modified) {
        file!.renameSync(path.path + '.bak');
        File(path.path).writeAsStringSync(sb.toString(), flush: true);
        print(sb.toString());
      }
    } catch (e) {
      if (!(e is FileSystemException)) {
        rethrow;
      }
    }
  }
}
