# Flutter工程条件编译打包脚本

## 原理
通过将 flutter run/build [--option] 命令替换为 bash flutter.sh run/build [--option] ，在原有flutter运行/打包流程前后执行内置及用户自定义脚本，从而实现对打包流程的自定义控制，默认内置功能为根据命令参数中的 --debug/release 以及 --flavor 渠道名，对代码和资源文件的条件编译

## 用法语法
### 代码：
代码中使用形如以下的注释来进行代码块的条件标记
```dart
void main(List<String> arguments) {
  print(1);
  // #[release[google]]
  // print(2);
  // #[release[!asd]]
  // print(3);
  // #[debug]
  // print(4);
  // #[release[test]]
  // print(5);
  // #[[test asd]]
  // print(6);
  // #[[]]
  // print(7)
  // #[[]]
}
```
基本注释标记语法为 **// #[debug/release[flavorName1 flavorName2 ...]]** ，外层方括号内填写debug模式或release模式，可以留空表示同时匹配两种模式；内层方括号内填写flavor名的列表，打包命令中 --flavor flavorName 参数传递进来的渠道名在列表中则匹配成功。

    特殊的，如果渠道名列表中的名称前加'！'表示取反，命令参数中传入的渠道名不在该列表中时匹配成功（ps: 注意普通渠道名条件列表与带取反的列表不能同时存在）
    
注释标记后紧跟该条件下的代码，并注意用 '// ' 进行代码注释，脚本解析时从上到下，某个注释标记的条件匹配成功，就会将紧跟的代码片段覆盖最近的默认代码块，并忽略掉两者之间的其他条件代码块。
默认代码块的前后需要用 '// #[[]]' 注释作为标记。

### 文件：
类似代码中注释条件标记的语法，文件名中使用形如 'abc[debug/release[flavorName1 flavorName2 ...]].xxx' 的形式进行文件命名，并用对应的 'abc.xxx' 文件名作为默认情况下使用的文件，即可在编译运行的时候自动根据传入参数将合适的文件替换为实际使用的文件，并在编译完成后自动还原。

# **WIP**