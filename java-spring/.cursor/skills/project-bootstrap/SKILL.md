---
name: project-bootstrap
version: 0.1.0
description: 扫描 Java Spring 多模块后端项目约定，生成 .cursor/project-conventions.md。用户说 bootstrap、扫描项目约定、对齐项目配置时触发。
---

# Project Bootstrap

## 流程

1. 确认当前目录是否为具体业务仓，而不是工作区根目录。
2. 读取 `pom.xml`，识别 Maven 模块。
3. 读取启动类、`application.yml`、Feign、Controller、Mapper 目录。
4. 生成 `.cursor/project-conventions.md`。

## 输出结构

```markdown
# Project Conventions

## 仓库信息

- 仓库名称：
- 服务名称：
- Java 版本：8
- Maven 模块：

## 入口与配置

- 启动类：
- 主配置：
- 端口：

## 分层约定

- API 模块：
- Core 模块：
- DAO 模块：
- Server 模块：

## 验证命令

- 最小编译：
- 仓级编译：
```

## 交付要求

说明扫描到的模块、入口、验证命令和未能确认的信息。
