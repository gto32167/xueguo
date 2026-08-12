# Xueguo Framework Rules

本仓库是跨项目复用的 Agent 研发协作框架，不承载某一个业务项目的业务代码和客户凭据。

## 修改规则

- 通用规则、模板和工具必须保持项目无关。
- 不要把 HiStore 的业务规则写入通用内核；项目差异放在项目配置或项目空间。
- 升级工具不得删除或覆盖项目任务、需求基线、变更单、发布记录和环境凭据。
- 不自动合并业务分支、不自动发布、不执行破坏性 Git 操作。
- 新增或修改注释、文档和日志使用 UTF-8 中文；交付前检查乱码、占位符和三连问号。
- 默认兼容 Windows PowerShell、Java 8 和 Maven 多模块项目。

## 验证

在本仓库执行：

```powershell
powershell -ExecutionPolicy Bypass -File tools\validate.ps1
```

验证接入升级流程：

```powershell
powershell -ExecutionPolicy Bypass -File tools\install.ps1 -Target E:\path\to\repo -ProjectId example
powershell -ExecutionPolicy Bypass -File tools\upgrade.ps1 -Target E:\path\to\repo -Check
```
