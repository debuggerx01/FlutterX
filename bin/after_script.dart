import 'dart:io';

void main(List<String> arguments) {
  print("running default after_script.");
  var rootDir = Directory('./');
  rootDir.listSync(recursive: true).forEach((p) {
    if (p.path.endsWith('.bak')) {
      File(p.path.substring(0, p.path.length - 4)).deleteSync();
      p.renameSync(p.path.substring(0, p.path.length - 4));
    }
  });
}
