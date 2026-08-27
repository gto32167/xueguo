---
name: project-bootstrap
version: 0.2.0
description: 扫描 Java Spring 多模块后端项目约定，生成 .cursor/project-conventions.md。用户说 bootstrap、扫描项目约定、对齐项目配置时触发。
---

# Project Bootstrap

## 流程

1. 确认当前目录是否为具体业务仓，而不是工作区根目录。
2. 读取 `pom.xml`，识别 Maven 模块。
3. 读取启动类、`application.yml`、Feign、Controller、Mapper 目录。
4. 读取 `.agent-workflow/config.yaml`；如果配置了项目空间，加载 `status/project-status.yaml` 和与当前任务相关的 `memory/` 索引。
5. 项目记忆按状态使用：`VERIFIED` 可作为已验证上下文，`CANDIDATE` 只能作为待核对线索，`DEPRECATED` 不得继续采用。
6. 生成或更新 `.cursor/project-conventions.md`，保留项目已确认的专属约定。

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

说明扫描到的模块、入口、验证命令、读取的项目记忆、当前待决策事项和未能确认的信息。不得把候选记忆描述为已确认事实。
