# ApplicationSet 实验使用指南

这个指南帮助您快速上手 ApplicationSet 的各种功能。

## 前置条件

1. 已部署 ArgoCD（参考 `02-installation.md`）
2. 已了解基本 Application 概念（参考 `03-first-application.md`）
3. 有可用的 Kubernetes 集群
4. 有 Git 仓库管理工具（GitHub/GitLab/Gitea）

## 实验步骤

### 步骤1: 准备 Git 仓库

```bash
# 1. 创建新的 Git 仓库
git clone https://github.com/yourusername/applicationset-demo.git
cd applicationset-demo

# 2. 复制示例配置文件
cp -r lab/argocd/applicationset/sample-apps/* .

# 3. 提交到 Git
git add .
git commit -m "Add sample application configurations"
git push origin main
```

### 步骤2: 修改 ApplicationSet 配置

编辑 `lab/argocd/applicationset/` 目录下的 YAML 文件，将 Git 仓库地址替换为您的实际地址：

```bash
# 查找所有需要替换的仓库地址
grep -r "github.com/your-org" lab/argocd/applicationset/

# 批量替换（使用 sed 或手动编辑）
sed -i 's|https://github.com/your-org|https://github.com/yourusername|g' *.yaml
```

### 步骤3: 部署 ApplicationSet

```bash
# 进入 ArgoCD 项目目录
cd /workspace/docs/ai-docs

# 部署单个 ApplicationSet（以 Git Directory Generator 为例）
kubectl apply -f lab/argocd/applicationset/git-directory-example.yaml

# 检查 ApplicationSet 状态
kubectl get applicationset -n argocd

# 查看生成的 Applications
kubectl get applications -n argocd -l generator=git-directory
```

### 步骤4: 验证部署结果

```bash
# 查看 ApplicationSet 详细信息
kubectl describe applicationset git-directory-example -n argocd

# 检查生成的某个 Application
kubectl describe application <app-name> -n argocd

# 验证实际部署的资源
kubectl get all -n <namespace>

# 查看 ArgoCD UI 中的应用状态
# 访问 https://localhost:8080 或配置的 ArgoCD 地址
```

## 实验场景

### 场景1: Git Directory Generator

**目标**：自动发现 Git 仓库中的目录并创建对应的应用

**步骤**：
1. 应用 `git-directory-example.yaml`
2. 在 Git 仓库中添加新目录 `environments/test/`
3. 推送代码变更
4. 观察 ArgoCD 自动创建新的 Application

### 场景2: List Generator 多环境部署

**目标**：为同一应用部署到多个环境

**步骤**：
1. 应用 `list-generator-example.yaml`
2. 观察生成 3 个不同环境的应用
3. 修改 list 中的参数（如副本数）
4. 重新应用配置，观察应用更新

### 场景3: Matrix Generator 微服务矩阵

**目标**：实现微服务的多环境部署矩阵

**步骤**：
1. 准备包含多个服务的 Git 仓库
2. 应用 `matrix-generator-example.yaml`
3. 观察生成的应用数量：服务数 × 环境数
4. 测试添加新服务或新环境

### 场景4: Git Files Generator 配置驱动

**目标**：基于配置文件灵活定义应用部署

**步骤**：
1. 在 Git 仓库的 `app-registry/` 目录添加服务配置文件
2. 应用 `git-files-example.yaml`
3. 测试修改配置文件后的应用更新

### 场景5: Cluster Generator 多集群

**目标**：为多个 Kubernetes 集群部署相同的应用

**步骤**：
1. 配置 ArgoCD 管理多个集群
2. 为集群添加标签
3. 应用 `cluster-generator-example.yaml`
4. 观察每个集群都部署了对应应用

## 故障排除

### 1. ApplicationSet 生成失败

```bash
# 查看 ApplicationSet 状态
kubectl describe applicationset <name> -n argocd

# 查看控制器日志
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller

# 常见原因：
# - Git 仓库地址错误
# - 认证问题
# - 路径匹配不正确
```

### 2. 应用不同步

```bash
# 手动触发同步
kubectl patch application <app-name> -n argocd -p '{"spec":{"sync":{"refresh":true}}}'

# 查看同步状态
kubectl get application <app-name> -n argocd -o yaml

# 查看详细错误信息
kubectl describe application <app-name> -n argocd
```

### 3. 模板渲染错误

```bash
# 验证模板语法
kubectl get applicationset <name> -n argocd -o yaml | grep -A 20 template:

# 检查参数是否正确传递
# 在模板中添加注释进行调试
```

## 进阶练习

### 练习1: 条件部署

修改 ApplicationSet 配置，只为特定条件的服务生成应用：

```yaml
# 添加条件判断
template:
  spec:
    # 只在非生产环境自动同步
    syncPolicy:
      automated:
        prune: '{{#if (eq env "prod")}}false{{else}}true{{/if}}'
```

### 练习2: 参数转换

使用 Go template 函数处理参数：

```yaml
metadata:
  name: '{{path.basename | lower}}-{{env | upper}}'
  annotations:
    generated.at: '{{now | date "2006-01-02T15:04:05Z"}}'
```

### 练习3: 集成 CI/CD

设置 GitHub Actions 或 GitLab CI，当配置变更时自动触发 ArgoCD 同步：

```yaml
# .github/workflows/argocd-sync.yml
name: Trigger ArgoCD Sync
on:
  push:
    paths:
    - 'k8s/**'
jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Trigger ArgoCD Sync
      run: |
        curl -X POST -H "Authorization: Bearer $ARGOCD_TOKEN" \
          https://argocd.example.com/api/v1/applications/<app-name>/sync
```

## 学习资源

- [ArgoCD ApplicationSet 官方文档](https://argocd-applicationset.readthedocs.io/)
- [ArgoCD 官方文档](https://argo-cd.readthedocs.io/)
- [Kustomize 官方文档](https://kustomize.io/)
- [Helm 官方文档](https://helm.sh/)

## 下一步

完成这些实验后，您可以：

1. 学习 ArgoCD Projects 进行更精细的权限管理
2. 探索 ArgoCD 的通知和监控功能
3. 集成 CI/CD 流水线实现完全自动化
4. 学习多集群管理的高级功能