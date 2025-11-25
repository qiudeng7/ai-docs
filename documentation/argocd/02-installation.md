# ArgoCD 学习 - 02：环境准备和安装指南

## 前置环境检查

### 必需工具
```bash
# 检查 kubectl 版本
kubectl version --client

# 检查 Docker 是否运行
docker version

# 检查 kind 是否安装
kind version
```

### 安装 kind (如果未安装)
```bash
# Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# 验证安装
kind version
```

## 创建本地 Kubernetes 集群

### 创建 kind 配置文件
```yaml
# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
```

### 创建集群
```bash
# 使用配置文件创建集群
kind create cluster --config kind-config.yaml --name argocd-learning

# 验证集群状态
kubectl cluster-info --context kind-argocd-learning
```

### 安装 Ingress Controller
```bash
# 安装 NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# 等待 Ingress Controller 就绪
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

## 安装 ArgoCD

### 方法一：使用官方 YAML 清单 (推荐)
```bash
# 创建 argocd 命名空间
kubectl create namespace argocd

# 安装 ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 等待所有 Pod 就绪
kubectl wait --for=condition=ready pod \
  --all -n argocd \
  --timeout=300s
```

### 方法二：使用 Helm (可选)
```bash
# 添加 ArgoCD Helm 仓库
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# 安装 ArgoCD
helm install argocd argo/argo-cd --namespace argocd --create-namespace
```

### 验证安装
```bash
# 检查 ArgoCD 组件状态
kubectl get pods -n argocd

# 检查服务状态
kubectl get svc -n argocd

# 应该看到以下组件：
# - argocd-application-controller
# - argocd-dex-server
# - argocd-redis
# - argocd-repo-server
# - argocd-server
```

## 访问 ArgoCD UI

### 配置 Ingress (可选，推荐)
```yaml
# argocd-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  ingressClassName: nginx
  rules:
  - host: argocd.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
```

```bash
# 应用 Ingress 配置
kubectl apply -f argocd-ingress.yaml

# 添加本地域名解析 (需要 root 权限)
echo "127.0.0.1 argocd.local" | sudo tee -a /etc/hosts
```

### 端口转发 (简单方式)
```bash
# 端口转发到本地
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 访问 https://localhost:8080
```

## 获取登录凭据

### 获取初始密码
```bash
# ArgoCD 的默认用户名是 admin
# 密码存储在 argocd-initial-admin-secret 中
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 首次登录
1. 访问 ArgoCD UI (https://localhost:8080 或 http://argocd.local)
2. 用户名：`admin`
3. 密码：使用上述命令获取的密码
4. 建议首次登录后立即修改密码

## 安装 ArgoCD CLI

### 方法一：使用包管理器
```bash
# macOS
brew install argocd

# Linux (下载二进制)
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# 验证安装
argocd version
```

### 配置 CLI
```bash
# 登录到 ArgoCD 服务器
argocd login localhost:8080

# 如果使用 HTTPS 且证书无效
argocd login localhost:8080 --insecure

# 验证登录
argocd account get
```

## 环境清理 (如果需要)
```bash
# 删除 ArgoCD
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd

# 删除 kind 集群
kind delete cluster --name argocd-learning
```

## 故障排除

### 常见问题

1. **Pod 启动失败**
```bash
# 查看 Pod 详情
kubectl describe pod -n argocd <pod-name>

# 查看 Pod 日志
kubectl logs -n argocd <pod-name>
```

2. **Ingress 不工作**
```bash
# 检查 Ingress Controller 状态
kubectl get pods -n ingress-nginx

# 检查 Ingress 配置
kubectl describe ingress argocd-server-ingress -n argocd
```

3. **CLI 无法连接**
```bash
# 检查端口转发是否运行
netstat -tlnp | grep 8080

# 检查 ArgoCD 服务器状态
kubectl get svc argocd-server -n argocd
```

## 验证环境就绪

运行以下命令验证环境：
```bash
#!/bin/bash
echo "检查 Kubernetes 集群..."
kubectl cluster-info

echo -e "\n检查 ArgoCD Pods..."
kubectl get pods -n argocd

echo -e "\n检查 ArgoCD CLI..."
argocd version

echo -e "\n获取 ArgoCD 服务地址..."
kubectl get svc -n argocd

echo -e "\n✅ 环境验证完成！"
```

## 下一步

环境搭建完成后，我们将在下一篇文档中：
1. 创建示例应用
2. 配置 Git 仓库
3. 部署第一个 ArgoCD Application

---

**练习建议**：
1. 尝试不同的安装方式 (Helm vs YAML)
2. 配置不同的访问方式 (Ingress vs Port Forward)
3. 熟悉 ArgoCD UI 界面和基本操作