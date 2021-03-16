class Args {
  Args(this.mode, this.flavor, this.isReplaceMode);

  String mode;
  String flavor;
  bool isReplaceMode;

  @override
  String toString() {
    return 'Current mode is $mode, and flavor is ${flavor == '' ? 'default' : flavor}${isReplaceMode ? ' , for replace' : ''}';
  }
}

Args parse(arguments) {
  var args = Args('debug', 'default', false);
  for (var value in arguments) {
    if (value == '--release') {
      args.mode = 'release';
    } else if (value == '--debug') {
      args.mode = 'debug';
    }
    if (value == '--flavor') {
      args.flavor = arguments[arguments.indexOf('--flavor') + 1];
    }
    if (value == '--replace') {
      args.isReplaceMode = true;
    }
  }
  print(args);
  return args;
}
