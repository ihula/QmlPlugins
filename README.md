# QmlPlugins

基于 Qt6/QML 的跨平台医疗报告管理系统。

## 功能特性

- 多语言支持（中文/英文）
- 主题切换（深色/浅色/蓝色）
- SQLite 数据库管理（线程安全、Schema自省、WAL模式）
- 报告模板管理
- 相机图像采集
- 用户权限管理（基于动作的多选权限模型）
- 数据字典管理
- 消息中心（统一消息/错误处理）
- 统计图表（基于 Qt Charts）

## 系统要求

- Qt 6.7+（Quick, Sql, QuickControls2, Charts, Widgets）
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
src/             - C++ 源代码
src/QmlUI/       - QML 业务界面（27个）
src/Components/  - QML 通用组件库（21个）
resources/       - 资源文件（图片/翻译/主题/壁纸）
bin/             - 运行时输出目录
spec/            - 技术规格文档
```

## 核心模块

| 模块 | 说明 |
|------|------|
| DbManager | 数据库管理器（单例、线程安全、Schema自省） |
| UserInfo | 用户信息管理（SHA256 + 盐值加密） |
| RoleManager | 角色权限管理（基于动作的多选模型） |
| Configer | 配置管理器（INI 存储与热重载） |
| MessageCenter | 消息中心（统一消息/错误处理枢纽） |
| Translater | 翻译管理器（中/英多语言） |
| HulaLogger | 日志系统（按日期分割文件输出） |
| IdGenerator | ID 生成器（雪花漂移算法） |

## 许可证

Apache License 2.0
