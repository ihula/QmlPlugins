# !!!需要先调用 set_source_files_properties 属性，然后再调用 qt_add_qML_module。
# !!!target_include_directories() 只能用于已经通过 add_executable() 或 add_library() 创建的目标。
cmake_minimum_required(VERSION 3.16)
set(APP_NAME "QmlPlugins")
project(${APP_NAME} VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/../../bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/../../bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/../../lib)

# 编译器警告
if(MSVC)
    add_compile_options(/W4)
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# 查找 Qt6 组件
find_package(Qt6 6.7 REQUIRED COMPONENTS Quick Sql QuickControls2 Charts Widgets)

# 标准项目设置
qt_standard_project_setup(REQUIRES 6.7)

# 创建可执行文件
qt_add_executable(${APP_NAME}
    src/main.cpp
    src/singleappwatcher.h
    src/singleton.h
    src/configer.h
    src/configer.cpp
    src/dbmanager.h
    src/dbmanager.cpp
    src/hulalogger.h
    src/hulalogger.cpp
    src/translater.h
    src/translater.cpp
    src/messagecenter.h
    src/messagecenter.cpp
    src/basemsgsender.h
    src/basemsgsender.cpp
    src/userinfo.h
    src/userinfo.cpp
    src/datadict.h
    src/datadict.cpp
    src/patients.h
    src/patients.cpp
#    src/idgenerator.h
    src/utils.h
    src/utils.cpp
)

# 使用 CMake 变量来定义 URI，供 CMake 使用
set(MODULE_URI "HulaPlugins")

# C++ 代码中需要用到这个宏，将其传递给编译器
target_compile_definitions(${APP_NAME} PRIVATE
    MODULE_URI="HulaPlugins"
    DEPLOY_MODE=0
)

target_include_directories(${APP_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

# 设置 QML 单例类型 (仅标记没有 pragma Singleton 的文件)
# !!!需要先调用 set_source_files_properties 属性，然后再调用 qt_add_qML_module。
set_source_files_properties(
    src/QmlUI/HulaTheme.qml
    src/QmlUI/DarkBlueTheme.qml
    src/QmlUI/BlueTheme.qml
    src/QmlUI/Themer.qml
    src/QmlUI/DbFields.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

# 定义 QML 源文件列表
file(GLOB_RECURSE QML_SOURCES_ABS
    src/QmlUI/*.qml
    src/Components/*.qml
)

set(QML_SOURCES "")
foreach(qml_file ${QML_SOURCES_ABS})
    file(RELATIVE_PATH rel_path ${CMAKE_CURRENT_SOURCE_DIR} ${qml_file})
    list(APPEND QML_SOURCES ${rel_path})
endforeach()

#Components
# 添加 QML 模块
qt_add_qml_module(${APP_NAME}
    URI ${MODULE_URI}
    VERSION 1.0
    QML_FILES
        ${QML_SOURCES}
    SOURCES
        src/common.h
        #src/translater.h src/translater.cpp
        src/userinfo.h src/userinfo.cpp
        src/messagecenter.h src/messagecenter.cpp
        src/configer.h src/configer.cpp
        src/datadict.h src/datadict.cpp
        src/patients.h src/patients.cpp
        src/utils.h src/utils.cpp
)

# 链接 Qt 库
target_link_libraries(${APP_NAME} PRIVATE
    Qt6::Quick
    Qt6::Sql
    Qt6::QuickControls2
    Qt6::Charts
    Qt6::Widgets
)

# 平台适配
if(UNIX AND NOT APPLE)
    # Linux 平台：修复 Qt 6.7+ 的 _Float16 问题
    target_compile_options(${APP_NAME} PRIVATE
        -DQT_NO_FLOAT16_OPERATORS
    )
endif()

if(WIN32)
    # Windows 平台：设置为 Win32 GUI 应用程序
    set_target_properties(${APP_NAME} PROPERTIES
        WIN32_EXECUTABLE TRUE
    )
    # 添加 Windows 资源文件
    target_sources(${APP_NAME} PRIVATE src/ico.rc)
endif()

if(APPLE)
    # macOS 平台：设置为 Bundle 应用程序
    set_target_properties(${APP_NAME} PROPERTIES
        MACOSX_BUNDLE_BUNDLE_VERSION "1.0"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0"
        MACOSX_BUNDLE TRUE
    )
endif()

# 安装目标
install(TARGETS ${APP_NAME}
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)


