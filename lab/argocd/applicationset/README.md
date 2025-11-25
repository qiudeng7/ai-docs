# ApplicationSet 实验配置

这个目录包含 ApplicationSet 学习的实验配置文件。

## 文件说明

- `git-directory-example.yaml` - Git Directory Generator 示例
- `list-generator-example.yaml` - List Generator 示例
- `matrix-generator-example.yaml` - Matrix Generator 示例
- `git-files-example.yaml` - Git Files Generator 示例
- `cluster-generator-example.yaml` - Cluster Generator 示例
- `microservices-appset.yaml` - 完整的微服务部署示例
- `sample-apps/` - 模拟的应用配置文件结构

## 使用方法

1. 首先创建一个 Git 仓库来存储应用配置
2. 将 `sample-apps/` 目录的内容复制到 Git 仓库
3. 修改 ApplicationSet 配置中的 Git 仓库地址
4. 应用 ApplicationSet 配置到 ArgoCD

## 实验步骤

参考 `../../documentation/argocd/04-applicationset.md` 中的详细实验步骤。