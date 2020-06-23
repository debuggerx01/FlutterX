import 'dart:io';

class PathUtils {
  static String baseName(FileSystemEntity file) {
    return file.path.substring(file.parent.path.length + 1);
  }
}

void main() {
  print(PathUtils.baseName(File('./path_utils.dart')));
}