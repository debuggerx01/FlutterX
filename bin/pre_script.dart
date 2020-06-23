import 'dart:io';
import 'parse_arguments.dart';
import 'path_utils.dart';

String mode;
List<String> flavors;
Args args;

enum STATE {
  none,
  notMatch,
  caching,
  cached,
  replace,
}

void main(List<String> arguments) {
  print("Running default pre_script.");
  args = parse(arguments);

  var rootDir = Directory('./');
  rootDir.listSync().forEach(walkPath);
}

File file;
StringBuffer sb = StringBuffer();
StringBuffer tmp = StringBuffer();
STATE state = STATE.none;
RegExp re = RegExp(r'// #\[(debug|release)?(?:\[(.*)\])?\]');
RegExp pathRe = RegExp(r'\[(debug|release)?(?:\[(.*)\])?\]');
Match ma;

void walkPath(FileSystemEntity path) {
  var stat = path.statSync();
  if (stat.type == FileSystemEntityType.directory) {
    Directory(path.path).listSync().forEach(walkPath);
  } else if (stat.type == FileSystemEntityType.file) {
    ma = pathRe.firstMatch(PathUtils.baseName(path));
    if (ma != null) {
      mode = ma.group(1);
      flavors = (ma.group(2) ?? '').split(' ').where((ele) => ele.trim() != '').toList();
      if (checkModeAndFlavors()) {
        var defaultFilePath = path.path.replaceFirst(ma.group(0), '');
        var defaultFile = File(defaultFilePath);
        if (defaultFile.existsSync()) {
          defaultFile.renameSync(defaultFilePath + '.default');
        }
        File(path.path).copySync(defaultFilePath);
      }
      return;
    }

    // 文件名不带规则，逐行读取后进行处理
    file = File(path.path);
    sb.clear();
    try {
      file.readAsLinesSync().forEach((line) {
        ma = re.firstMatch(line);
        if (ma != null) {
          mode = ma.group(1);
          flavors = (ma.group(2) ?? '').split(' ').where((ele) => ele.trim() != '').toList();

          // 默认的代码块
          if (mode == null && flavors.length == 0) {
            // 前一状态为replace，此时应该将缓存内容写入替换区域，并将状态复位为none
            if (state == STATE.replace) {
              sb.write(tmp);
              state = STATE.none;
            }
            // 前一状态为缓存中或缓存结束，此时应该将状态改为替换，用于跳过默认内容
            else if (state == STATE.caching || state == STATE.cached) {
              state = STATE.replace;
            }
          } else {
            // 带有条件的替换代码块
            if (state == STATE.caching) {
              // 此时状态为缓存中，将状态改为已缓存
              state = STATE.cached;
            } else if (state == STATE.none || state == STATE.notMatch) {
              // 此时状态为none或者未匹配，需要进行匹配判断
              if (checkModeAndFlavors()) {
                state = STATE.caching;
                tmp.clear();
              } else {
                state = STATE.notMatch;
              }
            }
          }
        } else {
          // none状态时直接将line写入sb
          if (state == STATE.none)
            sb.writeln(line);
          // 缓存中状态，将用于替换的内容移除注释后写入缓存
          else if (state == STATE.caching) tmp.writeln(line.replaceFirst('// ', ''));
          // 这样就跳过了没有匹配上的替换代码块和默认内容
        }
      });
      file.renameSync(path.path + '.bak');
      File(path.path).writeAsStringSync(sb.toString(), flush: true);
    } catch (e) {
      if (!(e is FileSystemException)) {
        rethrow;
      }
    }
  }
}

bool checkModeAndFlavors() {
  if (mode != null && mode != args.mode) {
    return false;
  }

  if (flavors.isEmpty) return true;

  if (flavors[0].startsWith('!')) {
    return !flavors.map((e) => e.replaceFirst('!', '')).toList().contains(args.flavor);
  } else {
    return flavors.contains(args.flavor);
  }
}
