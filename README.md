# QmlPlugins

基于 Qt6/QML 的跨平台医疗报告管理系统。

## 功能特性

- 多语言支持（中文/英文）
- 主题切换（深色/浅色/蓝色）
- SQLite 数据库管理
- 报告模板管理
- 相机图像采集
- 用户权限管理
- 数据字典管理

## 系统要求

- Qt 6.7+
- CMake 3.16+
- C++20 编译器
- SQLite3

## 构建步骤

```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --parallel
```

## 运行

```bash
./bin/QmlPlugins
```

## 目录结构

```
src/          - 源代码
src/QmlUI/    - QML界面文件
src/HulaUI/   - 自定义QML组件
src/Images/   - 图片资源
src/Languages/- 翻译文件
bin/          - 运行时目录
```

## 许可证

Apache License 2.0
