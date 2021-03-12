# Flutter工程条件编译打包脚本

## 原理

通过将 flutter run/build [--option] 命令替换为 bash flutter.sh run/build [--option] ，在原有flutter运行/打包流程前后执行内置及用户自定义脚本，从而实现对打包流程的自定义控制，默认内置功能为根据命令参数中的
--debug/release 以及 --flavor 渠道名，对代码条件编译.

## 用法语法

### 代码：

代码中使用形如以下的注释来进行代码块的条件标记

```dart
void main(List<String> arguments) {
  print(1);
  // #{{exp}}
  // print(2);
  // #{{default}}
  print(7);
  // #{{end}}
}
```

基本注释标记语法为 **// #{{exp | default | end}}** 