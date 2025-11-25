# ArgoCD 学习状态记录

## 学习者信息
- **用户已有知识**:
  - Linux 和容器化技术 (Docker, K8s, kind)
  - 开发: TypeScript(Vue), Python, 爬虫
  - DevOps: 云服务、CI/CD(GitHub Actions)、反向代理、内网穿透
  - 通用: 依赖管理、异步编程、设计模式、类型系统等

## 选择的学习模式
- **学习方式**: 实践驱动
- **学习重点**: 基础操作、企业级应用
- **当前进度**: 基础操作阶段

## 学习进度
- ✅ 已完成: GitOps 理念与 ArgoCD 简介
- ✅ 已完成: 环境准备和安装指南
- 🔄 进行中: 创建第一个 Application
- ⏳ 待完成: 基本操作和常用命令

## 用户当前状态
- ✅ 成功安装了 ArgoCD pods
- ✅ 通过网页访问了 ArgoCD UI
- ❌ 未安装 ArgoCD CLI

## 下一步计划
1. 创建示例 Git 仓库
2. 演示如何创建第一个 Application
3. 展示自动同步功能
4. 基本操作和常用命令

## 文档结构规划
```
documentation/argocd/
├── index.md              # 文档索引和学习路径
├── CLAUDE.md             # AI状态记录(本文件)
├── 01-introduction.md    # GitOps 理念与 ArgoCD 简介 ✅
├── 02-installation.md    # 环境准备和安装指南 ✅
├── 03-first-application.md # 创建第一个 Application 🔄
├── 04-basic-operations.md # 基本操作和常用命令 ⏳
└── 进阶篇 (待规划)
```

## 交互记录
- 用户选择了实践驱动的学习模式
- 重点关注基础操作，后续学习企业级应用特性
- 用户已成功搭建环境并通过 Web UI 访问
- 考虑到用户未安装 CLI，后续操作尽量提供 Web UI 和 CLI 两种方式

## 资源管理规则 (用户要求，根据 readme.md)
- **脚手架命令**: 直接在文档中注明可以使用脚手架命令
- **单个文件**: 直接用代码块写在文档里
- **引用源码仓库**: 直接相对路径引用 references 目录下的文件
- **原创多文件**: 写到 `lab/[tech]/[lab-name]/` 目录下，在文档中说明学习资源位置

## 当前目录结构
```
lab/
└── argocd/
    └── guestbook/
        ├── guestbook-app.yaml    # 主要示例应用
        ├── nginx-demo.yaml      # 练习用 Nginx 示例
        └── README.md            # 示例说明文档
```

## 待解决的问题
- 如何体现 AI 和人类的双重身份