# ArgoCD 学习 - 04：ApplicationSet 批量应用管理

**学习资源**：本篇文档中使用的示例配置位于 [`../../lab/argocd/applicationset/`](../../lab/argocd/applicationset/) 目录下。

## 什么是 ApplicationSet？

ApplicationSet 是 ArgoCD 的一个控制器，用于**批量生成和管理 ArgoCD Application**。它解决了在多环境、多团队、多集群场景下需要大量重复创建 Application 的问题。

### 核心价值

1. **模板化**：使用模板定义 Application 的通用结构
2. **参数化**：通过不同的参数生成不同的 Application
3. **自动化**：根据 Git 仓库结构、集群列表等自动生成 Application
4. **维护性**：减少重复配置，统一管理方式

### 与普通 Application 的区别

| 特性 | 普通 Application | ApplicationSet |
|------|------------------|----------------|
| 数量 | 手动创建，一个个管理 | 批量生成，自动管理 |
| 配置 | 每个应用独立配置 | 模板 + 参数，高度复用 |
| 维护 | 修改需要更新每个应用 | 修改模板，所有应用自动更新 |
| 适用场景 | 少量应用、特殊配置 | 大量相似应用、多环境部署 |

## ApplicationSet 工作原理

### 架构概述

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Generator     │───▶│   ApplicationSet │───▶│   Applications  │
│   (生成器)       │    │   (控制器)        │    │   (自动生成)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  参数来源        │    │   Template       │    │   ArgoCD UI     │
│ • Git 仓库       │    │   (模板)         │    │   (管理界面)     │
│ • 集群列表       │    │                  │    │                 │
│ • 自定义列表     │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### 工作流程

1. **Generator 发现参数**：从各种源获取参数值
2. **ApplicationSet 生成模板**：将参数应用到模板
3. **创建 Application**：根据渲染后的模板创建 Application
4. **持续同步**：当参数变化时，自动更新或删除 Application

## Generator 类型详解

### 1. Git Directory Generator

**适用场景**：根据 Git 仓库的目录结构自动生成应用

**工作原理**：扫描指定 Git 仓库的目录结构，每个符合条件的目录生成一个 Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: git-directory-example
  namespace: argocd
spec:
  generators:
  - git:
      repoURL: https://github.com/your-org/microservices.git
      revision: HEAD
      directories:
      - path: environments/*  # 扫描 environments 目录下的所有子目录
        exclude: true         # 排除这个路径
      - path: environments/production/*
      - path: environments/staging/*
  template:
    metadata:
      name: '{{path.basename}}-app'  # 使用目录名作为应用名
    spec:
      project: default
      source:
        repoURL: https://github.com/your-org/microservices.git
        targetRevision: HEAD
        path: '{{path}}'  # 使用发现的路径
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{path.basename}}'  # 使用目录名作为命名空间
```

**实际目录结构示例**：
```
microservices/
├── environments/
│   ├── production/
│   │   ├── user-service/
│   │   │   ├── deployment.yaml
│   │   │   └── service.yaml
│   │   └── order-service/
│   │       ├── deployment.yaml
│   │       └── service.yaml
│   └── staging/
│       ├── user-service/
│       └── order-service/
```

**生成的 Application**：
- `user-service-app` (production)
- `order-service-app` (production)
- `user-service-app` (staging)
- `order-service-app` (staging)

### 2. List Generator

**适用场景**：基于预定义的列表生成应用，如多环境、多区域部署

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: list-generator-example
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - cluster: in-cluster
        url: https://kubernetes.default.svc
        env: dev
      - cluster: production
        url: https://prod-k8s.example.com
        env: prod
      - cluster: staging
        url: https://staging-k8s.example.com
        env: staging
  template:
    metadata:
      name: 'myapp-{{env}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/your-org/app-configs.git
        targetRevision: HEAD
        path: 'overlays/{{env}}'  # 不同环境使用不同的 kustomize overlay
      destination:
        server: '{{url}}'
        namespace: myapp-{{env}}
```

### 3. Cluster Generator

**适用场景**：为 ArgoCD 管理的所有集群自动部署应用

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: cluster-generator-example
  namespace: argocd
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          env: production  # 只选择标记为 production 的集群
  template:
    metadata:
      name: 'monitoring-{{name}}'  # 使用集群名称
    spec:
      project: default
      source:
        repoURL: https://github.com/your-org/monitoring.git
        targetRevision: HEAD
        path: .
      destination:
        server: '{{server}}'  # 使用集群的 API Server 地址
        namespace: monitoring
```

### 4. Git Files Generator

**适用场景**：基于 Git 仓库中的配置文件生成应用

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: git-files-example
  namespace: argocd
spec:
  generators:
  - git:
      repoURL: https://github.com/your-org/app-configs.git
      revision: HEAD
      files:
      - path: 'apps/*/config.yaml'  # 匹配所有应用的配置文件
  template:
    metadata:
      name: '{{appName}}'
    spec:
      project: default
      source:
        repoURL: '{{gitRepoURL}}'
        targetRevision: '{{targetRevision}}'
        path: '{{path}}'
      destination:
        server: '{{cluster}}'
        namespace: '{{namespace}}'
```

**配置文件示例** (`apps/user-service/config.yaml`)：
```yaml
appName: user-service
cluster: https://kubernetes.default.svc
namespace: user-service
path: user-service
gitRepoURL: https://github.com/your-org/user-service.git
targetRevision: main
```

### 5. Matrix Generator

**适用场景**：组合多个生成器的参数，生成笛卡尔积的应用

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: matrix-generator-example
  namespace: argocd
spec:
  generators:
  - matrix:
      generators:
      - git:
          repoURL: https://github.com/your-org/services.git
          revision: HEAD
          directories:
          - path: services/*
      - list:
          elements:
          - env: dev
            replicas: 1
          - env: staging
            replicas: 2
          - env: prod
            replicas: 3
  template:
    metadata:
      name: '{{path.basename}}-{{env}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/your-org/services.git
        targetRevision: HEAD
        path: '{{path}}'
        helm:
          parameters:
          - name: replicaCount
            value: '{{replicas}}'
          - name: environment
            value: '{{env}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{path.basename}}-{{env}}'
```

**生成的应用**：
- `user-service-dev` (1 replica)
- `user-service-staging` (2 replicas)
- `user-service-prod` (3 replicas)
- `order-service-dev` (1 replica)
- `order-service-staging` (2 replicas)
- `order-service-prod` (3 replicas)

### 6. SCM Provider Generator

**适用场景**：基于 GitHub/GitLab 等代码托管平台的项目/仓库生成应用

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: scm-provider-example
  namespace: argocd
spec:
  generators:
  - scmProvider:
      github:
        # GitHub 连接配置
        apiURL: https://api.github.com
        # 使用 ArgoCD secret 中的 token
        tokenRef:
          secretName: github-token
          key: token
      # 过滤条件
      filters:
      - repositoryMatch: '.*-service'  # 只匹配以 -service 结尾的仓库
      - labelMatch: 'deploy'           # 只包含 deploy 标签的仓库
      # 分支过滤
      branchMatcher:
        regex: '^(main|master|develop)$'
  template:
    metadata:
      name: '{{repository}}-{{branch}}'
    spec:
      project: default
      source:
        repoURL: '{{url}}'
        targetRevision: '{{branch}}'
        path: k8s  # 假设所有服务的 k8s 配置都在 k8s 目录
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{repository}}'
```

## 实践案例：多环境微服务部署

让我们通过一个完整的实践案例来学习如何使用 ApplicationSet。

### 场景描述

假设我们有一个微服务架构的电商系统，包含以下服务：
- 用户服务 (user-service)
- 订单服务 (order-service)
- 支付服务 (payment-service)
- 商品服务 (product-service)

需要在三个环境部署：
- 开发环境 (dev)
- 预发布环境 (staging)
- 生产环境 (prod)

### 目录结构设计

```
microservices-config/
├── apps/
│   ├── user-service/
│   │   ├── base/
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   └── kustomization.yaml
│   │   ├── overlays/
│   │   │   ├── dev/
│   │   │   │   ├── kustomization.yaml
│   │   │   │   └── patch.yaml
│   │   │   ├── staging/
│   │   │   │   ├── kustomization.yaml
│   │   │   │   └── patch.yaml
│   │   │   └── prod/
│   │   │       ├── kustomization.yaml
│   │   │       └── patch.yaml
│   │   └── Chart.yaml  # Helm chart
│   ├── order-service/
│   │   └── ... (类似结构)
│   ├── payment-service/
│   │   └── ... (类似结构)
│   └── product-service/
│       └── ... (类似结构)
└── environments/
    ├── dev/
    │   ├── user-service-values.yaml
    │   ├── order-service-values.yaml
    │   ├── payment-service-values.yaml
    │   └── product-service-values.yaml
    ├── staging/
    │   └── ...
    └── prod/
        └── ...
```

### 配置文件准备

**学习资源**：示例文件已准备在 [`../../lab/argocd/applicationset/`](../../lab/argocd/applicationset/) 目录下。

1. **创建应用配置文件**

```bash
# 创建实验目录
mkdir -p lab/argocd/applicationset
cd lab/argocd/applicationset

# 从示例复制文件（如果已存在）
cp -r ../applicationset/* .
```

2. **部署 ApplicationSet**

```bash
# 应用 ApplicationSet 配置
kubectl apply -f applicationset-microservices.yaml

# 检查生成的 Application
kubectl get applications -n argocd

# 查看某个 ApplicationSet 的详情
kubectl get applicationset microservices-appset -n argocd -o yaml
```

### 实际部署步骤

#### 步骤1: 准备 Git 仓库

1. 创建或使用现有的 Git 仓库存储微服务配置
2. 按照上述目录结构组织配置文件
3. 确保每个服务都有对应的环境配置

#### 步骤2: 创建 ApplicationSet

```yaml
# lab/argocd/applicationset/microservices-appset.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: microservices-appset
  namespace: argocd
spec:
  generators:
  - matrix:
      generators:
      # 第一个生成器：发现所有服务
      - git:
          repoURL: https://github.com/your-org/microservices-config.git
          revision: HEAD
          directories:
          - path: apps/*
      # 第二个生成器：定义所有环境
      - list:
          elements:
          - env: dev
            namespace: microservices-dev
            valuesPath: environments/dev
          - env: staging
            namespace: microservices-staging
            valuesPath: environments/staging
          - env: prod
            namespace: microservices-prod
            valuesPath: environments/prod
  template:
    metadata:
      name: '{{path.basename}}-{{env}}'
      labels:
        app: '{{path.basename}}'
        environment: '{{env}}
        managed-by: applicationset
    spec:
      project: default
      source:
        repoURL: https://github.com/your-org/microservices-config.git
        targetRevision: HEAD
        path: '{{path}}/overlays/{{env}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{namespace}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
        - PrunePropagationPolicy=foreground
        retry:
          limit: 3
          backoff:
            duration: 5s
            factor: 2
            maxDuration: 3m
```

#### 步骤3: 验证部署

```bash
# 检查 ApplicationSet 状态
kubectl get applicationset microservices-appset -n argocd

# 查看生成的 Applications
kubectl get applications -n argocd -l managed-by=applicationset

# 检查具体应用状态
kubectl get applications -n argocd user-service-dev

# 查看部署的资源
kubectl get all -n microservices-dev -l app=user-service
```

## 高级功能和最佳实践

### 1. 条件生成

使用 `when` 条件控制哪些情况下生成 Application：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: conditional-example
spec:
  generators:
  - git:
      repoURL: https://github.com/your-org/configs.git
      revision: HEAD
      directories:
      - path: services/*
  template:
    metadata:
      name: '{{path.basename}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/your-org/configs.git
        targetRevision: HEAD
        path: '{{path}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{path.basename}}'
      # 只在特定条件下同步
      syncPolicy:
        automated: {}
        # 条件同步表达式
        when: '{{#if contains "prod" path.basename}}false{{else}}true{{/if}}'
```

### 2. 参数转换和过滤

使用 Go template 函数处理参数：

```yaml
template:
  metadata:
    name: '{{path.basename | lower}}-{{env | upper}}'
    annotations:
      service.name: '{{path.basename}}'
      environment: '{{env}}'
      generated.at: '{{now | date "2006-01-02T15:04:05Z"}}'
  spec:
    source:
      helm:
        # 处理 helm values
        valueFiles:
        - '{{#if (eq env "prod")}}values-prod.yaml{{else}}values-{{env}}.yaml{{/if}}'
        parameters:
        - name: image.tag
          value: '{{#if (eq env "prod")}}stable{{else}}latest{{/if}}'
```

### 3. 资源管理和策略

```yaml
template:
  spec:
    project: 'project-{{env}}'  # 不同环境使用不同项目
    source:
      repoURL: '{{repoURL}}'
      targetRevision: '{{#if (eq env "prod")}}main{{else}}develop{{/if}}'
      path: '{{path}}'
    destination:
      server: '{{cluster}}'
      namespace: '{{namespace}}'
    syncPolicy:
      automated:
        prune: '{{#if (eq env "prod")}}false{{else}}true{{/if}}'  # 生产环境不自动删除
        selfHeal: true
      syncOptions:
      - CreateNamespace=true
      - PruneLast=true  # 最后才删除命名空间
      - RespectIgnoreDifferences=true
      managedFieldsMetadata:
        operations: ['create', 'update']
```

### 4. 错误处理和重试策略

```yaml
template:
  spec:
    ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
      - /spec/replicas  # 忽略副本数的差异
    syncPolicy:
      retry:
        limit: 5  # 重试次数
        backoff:
          duration: 10s
          factor: 1.5
          maxDuration: 10m
```

## 常见问题和故障排除

### 1. ApplicationSet 不生成 Application

**可能原因**：
- Generator 配置错误
- Git 仓库访问问题
- 路径匹配不正确

**排查步骤**：
```bash
# 查看 ApplicationSet 状态
kubectl describe applicationset <name> -n argocd

# 查看 ApplicationSet Controller 日志
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller

# 测试 Generator 配置
kubectl get applicationset <name> -n argocd -o yaml | grep -A 10 generators
```

### 2. 生成错误的 Application

**问题**：Application 名称重复、路径错误等

**解决方案**：
- 使用模板函数确保名称唯一性
- 添加条件判断避免重复生成
- 使用 `metadata.nameSuffix` 区分不同应用

### 3. Git 仓库认证问题

**解决方案**：
```yaml
# 配置 Git 访问凭据
apiVersion: v1
kind: Secret
metadata:
  name: git-credentials
  namespace: argocd
type: Opaque
data:
  username: <base64-encoded-username>
  password: <base64-encoded-password>
  sshPrivateKey: <base64-encoded-private-key>

# 在 ApplicationSet 中引用
generators:
- git:
    repoURL: git@github.com:your-org/configs.git
    revision: HEAD
    directories:
    - path: services/*
    gitImplementation: go-git
    insecure: false
    # 引用凭据
    sshKeySecret:
      name: git-credentials
      key: sshPrivateKey
```

### 4. 性能优化

**问题**：大量应用导致生成缓慢

**优化策略**：
- 合理使用 Matrix Generator，避免笛卡尔积爆炸
- 使用 Git 文件缓存
- 限制并发生成的应用数量
- 定期清理不需要的 Application

```yaml
# 限制并发
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  applicationsetcontroller.enable.progressive.syncs: "true"
  applicationsetcontroller.parallelism.limit: "10"
```

## 实验练习

### 练习1: Git Directory Generator

创建一个基于目录结构的 ApplicationSet：
1. 创建包含多个微服务的 Git 仓库
2. 使用 Git Directory Generator 自动生成应用
3. 测试添加新目录时的自动发现功能

### 练习2: 多环境部署

使用 Matrix Generator 实现多环境部署：
1. 定义服务和环境的矩阵
2. 为不同环境配置不同的参数
3. 验证生成的应用数量和配置正确性

### 练习3: SCM Provider 集成

配置 SCM Provider Generator：
1. 连接到您的 GitHub/GitLab
2. 基于仓库标签自动生成应用
3. 测试新仓库创建时的自动发现

### 练习4: 条件和过滤

实现复杂的条件逻辑：
1. 只为特定标签的服务生成应用
2. 根据环境选择不同的部署策略
3. 使用模板函数处理参数转换

## 最佳实践总结

### 1. 目录结构设计

- **标准化**：建立统一的目录结构规范
- **层次化**：按应用、环境、版本组织目录
- **可扩展**：预留扩展空间，便于新增服务和环境

### 2. Generator 选择

| 场景 | 推荐的 Generator | 原因 |
|------|------------------|------|
| 微服务架构 | Git Directory | 自动发现新服务 |
| 多环境部署 | Matrix | 灵活的参数组合 |
| 多集群管理 | Cluster | 基于集群列表自动生成 |
| GitHub/GitLab | SCM Provider | 与代码仓库深度集成 |
| 配置文件驱动 | Git Files | 灵活的参数定义 |

### 3. 模板设计

- **参数化**：尽可能参数化，提高复用性
- **默认值**：为关键参数设置合理的默认值
- **验证**：使用条件判断确保配置正确性
- **文档化**：添加注释说明模板用途

### 4. 监控和维护

- **状态监控**：定期检查 ApplicationSet 和生成的 Application 状态
- **日志分析**：关注控制器日志，及时发现问题
- **定期清理**：删除不再需要的 Application 和配置
- **版本管理**：对 ApplicationSet 配置进行版本控制

### 5. 安全考虑

- **权限控制**：为不同环境配置不同的 RBAC 权限
- **凭据管理**：安全地管理 Git 仓库访问凭据
- **网络安全**：限制应用间的网络访问
- **审计日志**：记录所有应用生成和更新操作

## 下一步

现在您已经掌握了 ApplicationSet 的使用方法，可以：

1. **探索更复杂的场景**：多集群、多租户环境
2. **学习 ArgoCD Projects**：更好地组织和管理应用
3. **集成 CI/CD 流水线**：自动化整个部署流程
4. **监控和告警**：建立完善的可观测性体系
5. **最佳实践案例**：学习业界的大规模部署案例

---

**学习建议**：
1. 从简单的 Generator 开始，逐步增加复杂度
2. 在测试环境充分验证后再应用到生产环境
3. 建立完善的配置管理和版本控制流程
4. 定期回顾和优化 ApplicationSet 配置