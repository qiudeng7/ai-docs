# Gitea 部署示例

这是用于在 Kubernetes 上部署 Gitea 的 Helm Chart 配置示例。

## 文件说明

- `Chart.yaml`: Helm Chart 定义，声明对 Gitea 官方 chart 的依赖
- `values.yaml`: 自定义配置，适配 kind 环境和演示需求

## 配置特点

### 简化设计
- 使用 SQLite 数据库，避免外部数据库依赖
- 禁用 ingress，使用端口转发访问
- 使用 ClusterIP 服务类型

### 资源优化
- 适度的 CPU 和内存限制
- 1Gi 持久化存储
- 单副本部署（适合演示）

### 访问方式
```bash
# 端口转发访问
kubectl port-forward -n gitea svc/gitea-http 3000:3000
# 访问 http://localhost:3000
```

## 自定义选项

### 启用多副本
```yaml
replicaCount: 2
```

### 配置持久化存储
```yaml
persistence:
  enabled: true
  size: 5Gi
  storageClass: "fast-ssd"
```

### 启用 HTTPS
```yaml
service:
  https:
    enabled: true
```

## 部署命令

在包含这些文件的目录中：
```bash
# 添加 Gitea Helm 仓库
helm repo add gitea-charts https://gitea-charts.github.io/helm
helm repo update

# 部署 Gitea
helm install gitea gitea-charts/gitea -f values.yaml -n gitea --create-namespace
```

## 验证仓库
```bash
# 验证仓库是否可访问
helm search repo gitea

# 查看可用版本
helm search repo gitea -l
```