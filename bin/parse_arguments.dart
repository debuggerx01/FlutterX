class Args {
  Args(this.mode, this.flavor);

  String mode;
  String flavor;

  @override
  String toString() {
    return 'Current mode is $mode, and flavor is ${flavor == '' ? 'default' : flavor}';
  }
}

Args parse(arguments) {
  var args = Args('debug', 'default');
  for (var value in arguments) {
    if (value == '--release') {
      args.mode = 'release';
    } else if (value == '--debug') {
      args.mode = 'debug';
    }
    if (value == '--flavor') {
      args.flavor = arguments[arguments.indexOf('--flavor') + 1];
    }
  }
  print(args);
  return args;
}
