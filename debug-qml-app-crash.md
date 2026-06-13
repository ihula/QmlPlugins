# Debug Session: qml-app-crash

## Status: [OPEN]

## Symptom
- 程序启动后约6秒崩溃
- 日志显示 "The command terminated abnormal"

## Hypotheses
1. StatusCode 枚举未正确注册到 Qt 元对象系统
2. QML 模块加载失败
3. 数据库初始化失败
4. 资源文件/配置文件缺失

## Timeline
- 2026-06-14: Session opened, hypotheses proposed
