# ArgoCD 学习 - 03：部署第一个应用 - Gitea

**学习资源**：本篇文档中使用的示例配置位于 [`../../lab/argocd/gitea/`](../../lab/argocd/gitea/) 目录下。

## 准备工作

### 1. Gitea 介绍

我们将部署 **Gitea**，这是一个轻量级的 Git 服务，类似于 GitHub/GitLab：

- **功能**：提供 Git 仓库托管、代码管理、CI/CD 集成
- **特点**：轻量级、易部署、功能完整
- **适合**：团队协作、个人项目、CI/CD 学习
- **为什么选择 Gitea**：资源占用小、配置简单、功能丰富

### 2. 准备 Git 仓库

创建一个新仓库用于存储 Gitea 的 Kubernetes 配置：

```bash
# 在 GitHub/GitLab 创建新仓库后
git clone https://github.com/yourusername/argocd-gitea.git
cd argocd-gitea
```

### 3. 创建 Gitea 部署配置

我们将使用 Helm Chart 来部署 Gitea，这是官方推荐的部署方式。

**学习资源**：示例文件位于 [`../../lab/argocd/gitea/`](../../lab/argocd/gitea/) 目录下。

复制示例文件到您的 Git 仓库：

```bash
# 复制示例文件
cp -r lab/argocd/gitea/* .

# 提交到 Git
git add .
git commit -m "Add Gitea deployment configuration"
git push origin main
```

## 方法一：使用 Web UI 创建 Application (推荐)

### 步骤1: 登录 ArgoCD
1. 访问您的 ArgoCD UI (https://localhost:8080 或配置的域名)
2. 使用 admin 用户名和密码登录

### 步骤2: 创建新 Application
1. 点击左上角的 **"New App"** 按钮
2. 填写应用信息：

#### General 标签页:
```
Application Name: gitea
Project: default
Sync Policy: Manual (先选择手动，后续可以改为自动)
```

#### Source 标签页:
```
Repository URL: https://github.com/yourusername/argocd-gitea.git  # 换成您的仓库地址
Revision: HEAD
Path: .  # 所有配置文件在根目录
```

#### Destination 标签页:
```
Cluster URL: https://kubernetes.default.svc
Namespace: gitea  # 专门为 Gitea 创建命名空间
```

**Cluster URL 解释**：
- `https://kubernetes.default.svc` 是 Kubernetes 集群内部的 API Server 地址
- 这是 ArgoCD 部署所在的**当前集群**的默认地址
- `.svc` 后缀表示这是 Kubernetes 内部服务名称

### 步骤3: 创建并同步
1. 点击 **"Create"** 创建应用
2. 应用创建后，您会看到应用状态为 **"OutOfSync"**

**为什么是 OutOfSync 状态？**
- ArgoCD 创建了 Application 资源，但**还没有实际部署**应用
- Git 仓库中定义了期望状态，但集群中还没有这些资源
- `OutOfSync` 表示：集群实际状态 ≠ Git 中的期望状态
- 这是正常的初始状态，需要手动触发同步

3. 点击 **"Sync"** 按钮同步应用
4. 确认同步操作（查看将要创建的资源）

### 步骤4: 验证部署和访问应用

#### 验证部署状态
```bash
# 创建命名空间 (如果还没有)
kubectl create namespace gitea

# 检查 Gitea Pod 是否正常运行
kubectl get pods -n gitea -l app.kubernetes.io/name=gitea

# 检查 Service 状态
kubectl get service -n gitea

# 查看部署进度
kubectl logs -n gitea -l app.kubernetes.io/name=gitea
```

#### 访问 Gitea

Gitea 需要通过端口转发或 LoadBalancer 来访问：

**方式1: 端口转发 (推荐用于测试)**
```bash
# 将 Gitea 服务端口转发到本地
kubectl port-forward -n gitea svc/gitea-http 3000:3000

# 在浏览器访问 http://localhost:3000
```

**方式2: 使用 NodePort (需要修改配置)**
如果配置了 NodePort：
```bash
# 获取 NodePort 端口
kubectl get svc -n gitea gitea-http

# 通过节点 IP + NodePort 访问
# 对于 kind 环境，通常是 localhost:NodePort
```

#### 初始配置
首次访问 Gitea 时，您需要进行初始配置：
1. **数据库类型**：选择 SQLite（适合演示环境）
2. **管理员账号**：创建管理员用户
3. **服务设置**：可以保持默认配置

## 方法二：使用 ArgoCD CLI

如果您决定安装 CLI，可以使用以下命令：

```bash
# 登录 (如果之前未登录)
argocd login localhost:8080 --insecure

# 创建应用
argocd app create gitea \
  --repo https://github.com/yourusername/argocd-gitea.git \
  --path . \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace gitea \
  --sync-policy manual

# 同步应用
argocd app sync gitea

# 检查应用状态
argocd app get gitea
```

## 应用状态解析

### ArgoCD 中的状态指示器

1. **Sync Status (同步状态)**:
   - `Synced`: ✅ 集群实际状态与 Git 期望状态完全一致
   - `OutOfSync`: ❌ 集群状态与 Git 不一致，需要同步操作
   - `Unknown`: ❓ 无法确定同步状态（通常是网络或权限问题）

2. **Health Status (健康状态)**:
   - `Healthy`: ✅ 应用运行正常，所有 Pod 就绪
   - `Degraded`: ⚠️ 应用存在问题（如部分 Pod 异常，但服务仍可用）
   - `Progressing`: 🔄 应用正在更新中（如滚动更新）
   - `Missing`: ❌ 应用不存在于集群中
   - `Suspended`: ⏸️ 应用暂停同步

3. **Operation State (操作状态)**:
   - `Succeeded`: ✅ 最后一次操作（同步/回滚等）成功
   - `Failed`: ❌ 最后一次操作失败
   - `Running`: 🔄 操作正在进行中

### 状态组合示例

- **理想状态**: `Synced` + `Healthy` + `Succeeded`
- **刚创建应用**: `OutOfSync` + `Missing` (需要首次同步)
- **Git 有更新**: `OutOfSync` + `Healthy` (需要同步到最新版本)
- **部署中**: `OutOfSync` + `Progressing` + `Running`
- **部署失败**: `OutOfSync` + `Degraded` + `Failed`

## 演示 GitOps 工作流

现在让我们演示 GitOps 的核心特性：

### 1. 修改 Gitea 配置
编辑 Git 仓库中的配置文件，例如修改副本数：

```yaml
# 在 values.yaml 中修改
replicaCount: 2  # 从 1 改为 2
```

```bash
# 提交变更
git add values.yaml
git commit -m "Scale Gitea to 2 replicas"
git push origin main
```

### 2. 触发同步
在 ArgoCD UI 中：
1. 应用状态应该变为 `OutOfSync`
2. 点击 **"Sync"** 按钮
3. 观察同步过程

### 3. 验证变更
```bash
# 验证副本数变更
kubectl get pods -n gitea -l app.kubernetes.io/name=gitea

# 应该看到 2 个 Pod 在运行
kubectl get pods -n gitea -l app.kubernetes.io/name=gitea --show-labels

# 访问 Gitea 验证功能正常
# (如果之前的端口转发还在运行)
curl http://localhost:3000
```

### 4. 演示自愈特性
```bash
# 手动删除一个 Pod (模拟故障)
kubectl delete pod -n gitea -l app.kubernetes.io/name=gitea --random

# 观察 ArgoCD 如何重新创建 Pod
kubectl get pods -n gitea -l app.kubernetes.io/name=gitea -w

# 验证最终状态仍然是 2 个 Pod
kubectl get pods -n gitea -l app.kubernetes.io/name=gitea
```

## 高级配置选项

### 启用自动同步
如果您希望 ArgoCD 自动同步 Git 变更：

#### Web UI 方式:
1. 进入应用详情页面
2. 点击 **"App Details"** 标签页
3. 点击 **"EDIT"** 按钮
4. 在 **Sync Policy** 中启用 **Auto-Refresh**
5. 启用 **Auto-Sync** (可选)

#### 手动配置 Application CRD:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gitea
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/argocd-gitea.git
    targetRevision: HEAD
    path: .
  destination:
    server: https://kubernetes.default.svc
    namespace: gitea
  syncPolicy:
    automated:
      prune: false  # 是否自动删除 Git 中不存在的资源
      selfHeal: true  # 是否自动修复偏离的资源
    syncOptions:
    - CreateNamespace=true
```

## 常见问题和故障排除

### 1. 镜像拉取问题
```
ImagePullBackOff 或 ErrImagePull
```
**解决方案**:
- **网络问题**: gitea/gitea 镜像通常可以正常访问
- **镜像不存在**: 检查镜像标签是否正确
- **权限问题**: 确认镜像仓库访问权限

### 2. Git 仓库连接问题
```
Error: 无法连接到 Git 仓库
```
**解决方案**:
- 检查仓库 URL 是否正确
- 如果是私有仓库，配置访问凭据
- 确保网络连接正常

### 3. Helm Chart 仓库问题
```
Error: 404 Not Found 或 Unable to generate manifests
```
**解决方案**:
- **仓库地址错误**: 确认使用正确的 Helm 仓库地址
  ```bash
  # 验证仓库是否可访问
  helm repo add gitea-charts https://gitea-charts.github.io/helm
  helm repo update
  helm search repo gitea
  ```
- **网络问题**: 检查网络连接
- **Chart 版本**: 确认指定的 Chart 版本存在

### 4. 同步失败
```
Error: Sync operation failed
```
**解决方案**:
- 检查 Helm chart 配置语法
- 确保目标 namespace 存在
- 查看详细的错误信息

### 5. Gitea 访问问题
```
无法访问 http://localhost:3000
```
**解决方案**:
- 确认端口转发命令在运行
- 检查 Pod 是否正常运行: `kubectl get pods -n gitea`
- 查看应用日志: `kubectl logs -n gitea -l app.kubernetes.io/name=gitea`

## 实验练习

### 练习1: 自定义 Gitea 配置
尝试修改 Gitea 的配置：
- 修改服务端口
- 启用 HTTPS
- 配置持久化存储

**学习资源**：可修改 [`values.yaml`](../../lab/argocd/gitea/values.yaml) 文件。

### 练习2: 启用自动同步
1. 创建一个自动同步的 Application
2. 观察当您推送代码变更时自动部署的效果

### 练习3: 部署多个应用
创建多个应用：
- `gitea-prod` 部署到 `prod` namespace
- `gitea-dev` 部署到 `dev` namespace

## 下一步

现在您已经成功部署了 Gitea，这是一个真实可用的 Git 服务！后续步骤：

1. **使用 Gitea**: 创建一些测试仓库，体验 Git 服务功能
2. **学习 CI/CD**: Gitea 可以与 CI/CD 工具集成
3. **高级特性**: 了解 Gitea 的插件和扩展功能
4. **备份策略**: 学习如何备份 Gitea 的数据

---

**学习建议**：
1. 多尝试不同的配置选项
2. 熟悉 ArgoCD UI 的各个功能区域
3. 体验完整的 GitOps 工作流
4. 记录遇到的问题和解决方案