# Complete AWS EKS Guide: From Kubernetes Basics to Production

## Table of Contents

1. [Introduction to Containerization](#introduction)
2. [Kubernetes Fundamentals](#k8s-fundamentals)
3. [AWS EKS Overview](#eks-overview)
4. [EKS Architecture Deep Dive](#eks-architecture)
5. [Setting Up EKS](#eks-setup)
6. [Workload Management](#workload-management)
7. [Networking in EKS](#networking)
8. [Security Best Practices](#security)
9. [Monitoring and Logging](#monitoring)
10. [Cost Optimization](#cost-optimization)
11. [Production Best Practices](#production-practices)
12. [Troubleshooting](#troubleshooting)

---

## 1. Introduction to Containerization {#introduction}

### Why Containers?

**Traditional Deployment Challenges:**
- Environment inconsistency ("It works on my machine")
- Resource wastage with VMs
- Complex dependency management
- Slow deployment and scaling

**Container Benefits:**
- Lightweight and portable
- Consistent environments
- Fast startup times
- Resource efficiency
- Easy scaling and deployment

### Docker Fundamentals

```bash
# Basic Docker Commands
docker build -t myapp:v1 .
docker run -d -p 8080:80 myapp:v1
docker ps
docker logs <container-id>
docker exec -it <container-id> /bin/bash
```

**Dockerfile Example:**
```dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### Container vs Virtual Machine

| Aspect | Virtual Machine | Container |
|--------|----------------|-----------|
| Size | GBs | MBs |
| Startup Time | Minutes | Seconds |
| Resource Usage | High | Low |
| Isolation | Complete | Process-level |
| Portability | Limited | High |

---

## 2. Kubernetes Fundamentals {#k8s-fundamentals}

### What is Kubernetes?

Kubernetes (K8s) is an open-source container orchestration platform that automates:
- Container deployment
- Scaling and load balancing
- Service discovery and networking
- Health monitoring and self-healing
- Configuration and secret management

### Core Kubernetes Objects

#### 2.1 Pod - The Smallest Deployable Unit

**What is a Pod?**
- Wrapper around one or more containers
- Shared network and storage
- Ephemeral by nature
- Usually contains one main container

```yaml
# basic-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.20
    ports:
    - containerPort: 80
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

**Pod Lifecycle:**
1. **Pending**: Pod accepted but not scheduled
2. **Running**: Pod scheduled and running
3. **Succeeded**: All containers terminated successfully
4. **Failed**: At least one container failed
5. **Unknown**: Pod status cannot be determined

#### 2.2 Deployment - Managing Pod Replicas

**Why Deployments?**
- Desired state management
- Rolling updates and rollbacks
- Scaling capabilities
- Self-healing

```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Deployment Strategies:**
- **Recreate**: Terminate old, create new (downtime)
- **Rolling Update**: Gradual replacement (default, zero downtime)
- **Blue/Green**: Deploy to new environment, switch traffic
- **Canary**: Gradual traffic shift to new version

#### 2.3 Service - Network Abstraction

**Service Types:**
- **ClusterIP**: Internal cluster communication (default)
- **NodePort**: External access via node IP
- **LoadBalancer**: Cloud provider load balancer
- **ExternalName**: DNS CNAME mapping

```yaml
# nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  type: ClusterIP
---
# LoadBalancer Service for external access
apiVersion: v1
kind: Service
metadata:
  name: nginx-loadbalancer
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

#### 2.4 ConfigMap and Secret - Configuration Management

**ConfigMap for Non-sensitive Data:**
```yaml
# app-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_host: "postgres.example.com"
  database_port: "5432"
  log_level: "info"
  app.properties: |
    server.port=8080
    server.servlet.context-path=/api
```

**Secret for Sensitive Data:**
```yaml
# app-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  database_username: dXNlcm5hbWU=  # base64 encoded
  database_password: cGFzc3dvcmQ=  # base64 encoded
```

**Using ConfigMap and Secret in Deployment:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web-app
        image: myapp:latest
        env:
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database_host
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database_username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database_password
        volumeMounts:
        - name: config-volume
          mountPath: /app/config
      volumes:
      - name: config-volume
        configMap:
          name: app-config
```

#### 2.5 Namespace - Resource Isolation

**Why Namespaces?**
- Multi-tenancy
- Resource organization
- Access control boundaries
- Resource quotas

```yaml
# development-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: development
  labels:
    environment: dev
---
# Resource Quota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: development
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "20"
    services: "10"
```

### Kubernetes Architecture

#### Control Plane Components

1. **API Server (kube-apiserver)**
   - Frontend for Kubernetes control plane
   - Validates and configures data for API objects
   - Entry point for all administrative tasks

2. **etcd**
   - Consistent and highly-available key-value store
   - Stores all cluster data
   - Source of truth for cluster state

3. **Scheduler (kube-scheduler)**
   - Assigns pods to nodes
   - Considers resource requirements, constraints, and policies

4. **Controller Manager (kube-controller-manager)**
   - Runs controller processes
   - Node Controller, Replication Controller, Service Controller

#### Node Components

1. **kubelet**
   - Primary node agent
   - Manages containers and pods
   - Communicates with API server

2. **kube-proxy**
   - Network proxy on each node
   - Maintains network rules
   - Enables service abstraction

3. **Container Runtime**
   - Software responsible for running containers
   - Docker, containerd, CRI-O

### Essential kubectl Commands

```bash
# Cluster Information
kubectl cluster-info
kubectl get nodes
kubectl describe node <node-name>

# Working with Pods
kubectl get pods
kubectl get pods -n <namespace>
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- /bin/bash

# Working with Deployments
kubectl get deployments
kubectl create deployment nginx --image=nginx
kubectl scale deployment nginx --replicas=5
kubectl rollout status deployment/nginx
kubectl rollout history deployment/nginx
kubectl rollout undo deployment/nginx

# Working with Services
kubectl get services
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Configuration Management
kubectl apply -f deployment.yaml
kubectl delete -f deployment.yaml
kubectl get all
kubectl get all -n <namespace>

# Debugging and Troubleshooting
kubectl describe pod <pod-name>
kubectl logs <pod-name> -f
kubectl top nodes
kubectl top pods
```

---

## 3. AWS EKS Overview {#eks-overview}

### What is Amazon EKS?

Amazon Elastic Kubernetes Service (EKS) is a managed Kubernetes service that:
- Runs and scales the Kubernetes control plane
- Provides high availability across multiple AZs
- Integrates with AWS services
- Handles security patches and updates
- Offers managed node groups

### EKS vs Self-Managed Kubernetes

| Aspect | EKS | Self-Managed |
|--------|-----|--------------|
| Control Plane | AWS Managed | Self Managed |
| Updates | Automatic | Manual |
| High Availability | Built-in | Manual Setup |
| Security | AWS Responsibility | Your Responsibility |
| Cost | $0.10/hour per cluster | Infrastructure costs |
| Integration | Native AWS | Manual Setup |

### EKS Service Architecture

```
┌─────────────────────────────────────────────────────┐
│                  AWS Account                        │
├─────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────┐   │
│  │              EKS Control Plane              │   │
│  │          (Managed by AWS)                   │   │
│  │  ┌─────────────────────────────────────┐   │   │
│  │  │  API Server │ etcd │ Scheduler       │   │   │
│  │  │  Controller Manager │ Cloud Manager   │   │   │
│  │  └─────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────┘   │
│                       │                             │
│  ┌─────────────────────┼─────────────────────┐      │
│  │                    VPC                    │      │
│  │    ┌───────────────┴───────────────┐     │      │
│  │    │         Worker Nodes          │     │      │
│  │    │                               │     │      │
│  │    │  ┌─────┐  ┌─────┐  ┌─────┐   │     │      │
│  │    │  │Pod1 │  │Pod2 │  │Pod3 │   │     │      │
│  │    │  └─────┘  └─────┘  └─────┘   │     │      │
│  │    │                               │     │      │
│  │    │  kubelet │ kube-proxy │ CNI   │     │      │
│  │    └───────────────────────────────┘     │      │
│  └───────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────┘
```

### Key EKS Components

#### 1. EKS Control Plane
- Managed by AWS
- Runs in AWS-managed VPC
- Highly available across multiple AZs
- Automatically scaled and patched

#### 2. Worker Nodes
- EC2 instances in your VPC
- Run kubelet, kube-proxy, and container runtime
- Can be managed or self-managed
- Support spot instances for cost optimization

#### 3. Networking
- VPC CNI for pod networking
- Native VPC IP addressing
- Security groups for pods
- Load balancer integration

#### 4. Storage
- EBS CSI driver for persistent volumes
- EFS CSI driver for shared storage
- FSx CSI driver for high-performance workloads

### EKS Pricing Model

**Control Plane:**
- $0.10 per hour per cluster
- ~$73 per month per cluster

**Worker Nodes:**
- Standard EC2 pricing
- Spot instances available for cost savings
- Fargate pricing for serverless containers

**Add-ons:**
- VPC CNI, CoreDNS, kube-proxy (free)
- AWS Load Balancer Controller (free)
- Additional add-ons may have charges

---

## 4. EKS Architecture Deep Dive {#eks-architecture}

### EKS Control Plane Architecture

The EKS control plane consists of multiple components running across multiple Availability Zones:

```
┌─────────────────────────────────────────────────────────┐
│                 AWS Managed VPC                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │                  AZ-1a                          │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────────────┐   │   │
│  │  │   API   │ │  etcd   │ │    Scheduler    │   │   │
│  │  │ Server  │ │ Master  │ │   Controller    │   │   │
│  │  └─────────┘ └─────────┘ └─────────────────┘   │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │                  AZ-1b                          │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────────────┐   │   │
│  │  │   API   │ │  etcd   │ │   Controller    │   │   │
│  │  │ Server  │ │ Replica │ │    Manager      │   │   │
│  │  └─────────┘ └─────────┘ └─────────────────┘   │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │                  AZ-1c                          │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────────────┐   │   │
│  │  │   API   │ │  etcd   │ │ Cloud Controller│   │   │
│  │  │ Server  │ │ Replica │ │    Manager      │   │   │
│  │  └─────────┘ └─────────┘ └─────────────────┘   │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                           │
                  ┌────────┴────────┐
                  │   Customer VPC   │
                  │  (Worker Nodes)  │
                  └──────────────────┘
```

### Worker Node Types

#### 1. Managed Node Groups

**Benefits:**
- Automated provisioning and lifecycle management
- Automatic security patches and updates
- Integration with cluster autoscaler
- Simplified scaling operations

```yaml
# managed-nodegroup-config.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: production-cluster
  region: us-west-2

managedNodeGroups:
- name: managed-nodes
  instanceType: m5.large
  minSize: 1
  maxSize: 10
  desiredCapacity: 3
  
  # EBS Volume Configuration
  volumeSize: 100
  volumeType: gp3
  volumeEncrypted: true
  
  # Networking
  privateNetworking: true
  subnets:
    - subnet-12345
    - subnet-67890
  
  # Security
  securityGroups:
    attachIDs: ["sg-12345"]
  
  # Labels and Tags
  labels:
    Environment: production
    NodeType: managed
  
  tags:
    Environment: production
    ManagedBy: eksctl
```

#### 2. Self-Managed Node Groups

**Use Cases:**
- Custom AMIs
- Specific instance configurations
- Advanced networking requirements
- Custom bootstrap scripts

```yaml
# self-managed-nodegroup.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: production-cluster
  region: us-west-2

nodeGroups:
- name: custom-nodes
  instanceType: m5.xlarge
  minSize: 2
  maxSize: 20
  desiredCapacity: 5
  
  # Custom AMI
  ami: ami-12345678
  amiFamily: AmazonLinux2
  
  # Instance Store
  instancesDistribution:
    maxPrice: 0.50
    instanceTypes: ["m5.large", "m5.xlarge", "m4.large"]
    onDemandBaseCapacity: 2
    onDemandPercentageAboveBaseCapacity: 50
    spotInstancePools: 3
  
  # Custom user data
  preBootstrapCommands:
    - echo "Custom bootstrap script"
    - yum update -y
  
  # SSH access
  ssh:
    allow: true
    publicKeyName: my-key-pair
```

#### 3. Fargate Profiles

**Serverless Container Compute:**
- No node management
- Pay per pod
- Automatic scaling
- Isolated compute environment

```yaml
# fargate-profile.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: serverless-cluster
  region: us-west-2

fargateProfiles:
- name: fp-default
  selectors:
  - namespace: default
    labels:
      compute-type: fargate
  
- name: fp-backend
  selectors:
  - namespace: backend
    labels:
      app: api-server
  
  # Custom pod execution role
  podExecutionRoleARN: "arn:aws:iam::123456789012:role/CustomPodExecutionRole"
  
  # Subnets (must be private)
  subnets:
    - subnet-private-1
    - subnet-private-2
```

### EKS Networking Deep Dive

#### VPC CNI Plugin

The Amazon VPC CNI plugin provides native VPC networking for pods:

**Key Features:**
- Pods get VPC IP addresses
- High network performance
- Security group support for pods
- Network policy support

**CNI Configuration:**
```yaml
# vpc-cni-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: amazon-vpc-cni
  namespace: kube-system
data:
  enable-prefix-delegation: "true"
  enable-pod-eni: "true"
  eni-config-label-def: "topology.kubernetes.io/zone"
  enable-network-policy-controller: "true"
  
  # IP address management
  warm-prefix-target: "1"
  warm-ip-target: "10"
  minimum-ip-target: "5"
```

#### Pod-to-Pod Communication Flow

```
┌─────────────────────────────────────────────────────┐
│                   Worker Node                       │
│  ┌─────────────────────────────────────────────┐   │
│  │              Pod Namespace                  │   │
│  │  ┌─────┐    ┌─────┐    ┌─────┐             │   │
│  │  │Pod A│    │Pod B│    │Pod C│             │   │
│  │  │10.0.│    │10.0.│    │10.0.│             │   │
│  │  │1.100│    │1.101│    │1.102│             │   │
│  │  └─────┘    └─────┘    └─────┘             │   │
│  │     │          │          │                │   │
│  │  ┌──┴──────────┴──────────┴──┐             │   │
│  │  │        Bridge (br0)       │             │   │
│  │  └─────────────┬─────────────┘             │   │
│  └────────────────┼─────────────────────────────┘   │
│                   │                                 │
│  ┌────────────────┴─────────────────────────────┐   │
│  │              Primary ENI                     │   │
│  │            (10.0.1.10)                       │   │
│  └──────────────────┬───────────────────────────┘   │
└─────────────────────┼───────────────────────────────┘
                      │
    ┌─────────────────┴─────────────────┐
    │           VPC Route Table         │
    │  10.0.1.0/24 → Local             │
    │  0.0.0.0/0 → Internet Gateway     │
    └───────────────────────────────────┘
```

### EKS Add-ons

#### Core Add-ons

1. **VPC CNI**
   - Pod networking
   - IP address management
   - Security group enforcement

2. **CoreDNS**
   - Cluster DNS service
   - Service discovery
   - DNS policy management

3. **kube-proxy**
   - Service load balancing
   - Network rules management
   - iptables/ipvs configuration

#### Additional Add-ons

1. **AWS Load Balancer Controller**
   - ALB/NLB integration
   - Ingress controller
   - Service type LoadBalancer

2. **EBS CSI Driver**
   - Persistent volume support
   - Dynamic provisioning
   - Snapshot capabilities

3. **Cluster Autoscaler**
   - Automatic node scaling
   - Cost optimization
   - Multi-AZ support

---

## 5. Setting Up EKS {#eks-setup}

### Prerequisites

#### Required Tools

```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installations
aws --version
eksctl version
kubectl version --client
helm version
```

#### AWS Configuration

```bash
# Configure AWS CLI
aws configure
# Enter:
# - AWS Access Key ID
# - AWS Secret Access Key  
# - Default region (e.g., us-west-2)
# - Default output format (json)

# Verify configuration
aws sts get-caller-identity
```

#### Required IAM Permissions

The user/role creating EKS clusters needs these permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*",
                "ec2:*",
                "iam:*",
                "cloudformation:*",
                "autoscaling:*",
                "logs:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### Creating EKS Cluster

#### Method 1: Using eksctl (Recommended for Learning)

**Simple Cluster Creation:**
```bash
# Create basic cluster
eksctl create cluster \
  --name learning-cluster \
  --version 1.28 \
  --region us-west-2 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed
```

**Advanced Cluster with Configuration File:**
```yaml
# cluster-config.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: production-cluster
  region: us-west-2
  version: "1.28"

# IAM and Security
iam:
  withOIDC: true
  serviceAccounts:
  - metadata:
      name: aws-load-balancer-controller
      namespace: kube-system
    wellKnownPolicies:
      awsLoadBalancerController: true
  - metadata:
      name: cluster-autoscaler
      namespace: kube-system  
    wellKnownPolicies:
      autoScaler: true

# VPC Configuration
vpc:
  cidr: "10.0.0.0/16"
  nat:
    gateway: HighlyAvailable
  clusterEndpoints:
    privateAccess: true
    publicAccess: true
    publicAccessCIDRs: ["203.0.113.0/24"]  # Your IP range

# Managed Node Groups
managedNodeGroups:
- name: general-purpose
  instanceType: m5.large
  minSize: 2
  maxSize: 10
  desiredCapacity: 3
  
  # Node configuration
  volumeSize: 100
  volumeType: gp3
  volumeEncrypted: true
  
  # Networking
  privateNetworking: true
  
  # Security
  securityGroups:
    withShared: true
    withLocal: true
  
  # SSH access (optional)
  ssh:
    allow: false  # Recommended for security
  
  # Labels and taints
  labels:
    role: general-purpose
    environment: production
  
  tags:
    Environment: production
    NodeGroup: general-purpose

# Fargate Profile
fargateProfiles:
- name: serverless-workloads
  selectors:
  - namespace: fargate-namespace
    labels:
      compute-type: fargate

# Add-ons
addons:
- name: vpc-cni
  version: latest
- name: coredns
  version: latest  
- name: kube-proxy
  version: latest
- name: aws-ebs-csi-driver
  version: latest

# Logging
logging:
  enable:
    - api
    - audit
    - authenticator
    - controllerManager
    - scheduler
  logRetentionInDays: 30
```

**Create cluster using config file:**
```bash
eksctl create cluster -f cluster-config.yaml
```

#### Method 2: Using AWS Console

1. **Navigate to EKS Console**
   - Open AWS Console
   - Go to Elastic Kubernetes Service
   - Click "Create cluster"

2. **Configure Cluster**
   - Cluster name: `my-cluster`
   - Kubernetes version: `1.28`
   - Cluster service role: Select existing or create new

3. **Specify Networking**
   - VPC: Select VPC
   - Subnets: Select subnets (minimum 2)
   - Security groups: Configure access
   - Endpoint access: Public and private (recommended)

4. **Configure Logging**
   - Enable desired log types
   - CloudWatch log group will be created

5. **Review and Create**

#### Method 3: Using Terraform

```hcl
# main.tf
provider "aws" {
  region = "us-west-2"
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "terraform-cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
    security_group_ids      = [aws_security_group.cluster.id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_cloudwatch_log_group.cluster,
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/terraform-cluster/cluster"
  retention_in_days = 30
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "terraform-nodes"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = aws_subnet.private[*].id

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 1
  }

  update_config {
    max_unavailable = 2
  }

  remote_access {
    ec2_ssh_key = "my-key-pair"
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Post-Deployment Configuration

#### Update kubeconfig

```bash
# Update kubeconfig for kubectl access
aws eks update-kubeconfig --region us-west-2 --name production-cluster

# Verify cluster access
kubectl get nodes
kubectl get pods --all-namespaces

# Check cluster information
kubectl cluster-info
```

#### Install Essential Add-ons

**1. AWS Load Balancer Controller:**
```bash
# Create IAM service account
eksctl create iamserviceaccount \
  --cluster=production-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --approve

# Install using Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=production-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Verify installation
kubectl get deployment -n kube-system aws-load-balancer-controller
```

**2. EBS CSI Driver:**
```bash
# Install EBS CSI driver add-on
eksctl create addon \
  --name aws-ebs-csi-driver \
  --cluster production-cluster \
  --service-account-role-arn arn:aws:iam::ACCOUNT_ID:role/AmazonEKS_EBS_CSI_DriverRole \
  --force

# Verify installation
kubectl get pods -n kube-system -l app=ebs-csi-controller
```

**3. Cluster Autoscaler:**
```bash
# Apply cluster autoscaler
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Configure cluster autoscaler
kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"

# Edit deployment to add cluster name and other configurations
kubectl -n kube-system edit deployment.apps/cluster-autoscaler
```

---

## 6. Workload Management {#workload-management}

### Pod Lifecycle and Management

#### Pod Phases

1. **Pending**: Pod accepted but containers not created
2. **Running**: Pod scheduled and at least one container running
3. **Succeeded**: All containers terminated successfully
4. **Failed**: At least one container failed
5. **Unknown**: Pod state cannot be obtained

#### Pod Restart Policies

```yaml
# pod-restart-policies.yaml
apiVersion: v1
kind: Pod
metadata:
  name: restart-policy-demo
spec:
  restartPolicy: Always  # Always, OnFailure, Never
  containers:
  - name: app
    image: busybox
    command: ['sh', '-c', 'echo Hello && sleep 3600']
```

#### Advanced Pod Configuration

```yaml
# advanced-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: advanced-pod
  labels:
    app: demo
    tier: frontend
  annotations:
    description: "Demo pod with advanced configuration"
spec:
  # Security Context
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
    
  # Node Selection
  nodeSelector:
    disktype: ssd
    
  # Tolerations for taints
  tolerations:
  - key: "spot-instance"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
    
  # Affinity rules
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/arch
            operator: In
            values:
            - amd64
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - demo
          topologyKey: kubernetes.io/hostname
          
  # Init containers
  initContainers:
  - name: init-db
    image: busybox:1.28
    command: ['sh', '-c', 'until nslookup mydb; do echo waiting for mydb; sleep 2; done;']
    
  # Main containers
  containers:
  - name: web-server
    image: nginx:1.20
    ports:
    - containerPort: 80
      name: http
    
    # Resource requests and limits
    resources:
      requests:
        memory: "128Mi"
        cpu: "250m"
      limits:
        memory: "256Mi"
        cpu: "500m"
        
    # Environment variables
    env:
    - name: DATABASE_URL
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: db-url
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: log-level
          
    # Volume mounts
    volumeMounts:
    - name: app-storage
      mountPath: /data
    - name: config-volume
      mountPath: /etc/config
      
    # Health checks
    livenessProbe:
      httpGet:
        path: /health
        port: 80
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
      
    readinessProbe:
      httpGet:
        path: /ready
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
      
    # Lifecycle hooks
    lifecycle:
      preStop:
        exec:
          command: ["/bin/sh", "-c", "nginx -s quit; while killall -0 nginx; do sleep 1; done"]
          
  # Volumes
  volumes:
  - name: app-storage
    persistentVolumeClaim:
      claimName: app-pvc
  - name: config-volume
    configMap:
      name: app-config
      
  # DNS Configuration
  dnsPolicy: ClusterFirst
  dnsConfig:
    options:
    - name: ndots
      value: "2"
```

### Deployment Strategies

#### Rolling Update Strategy

```yaml
# rolling-update-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rolling-update-app
spec:
  replicas: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2          # Maximum additional pods during update
      maxUnavailable: 2    # Maximum unavailable pods during update
  selector:
    matchLabels:
      app: rolling-app
  template:
    metadata:
      labels:
        app: rolling-app
    spec:
      containers:
      - name: app
        image: nginx:1.20
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

#### Blue-Green Deployment

```yaml
# blue-green-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: app-service
spec:
  selector:
    app: web-app
    version: blue  # Switch between blue and green
  ports:
  - port: 80
    targetPort: 8080
---
# Blue deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
      version: blue
  template:
    metadata:
      labels:
        app: web-app
        version: blue
    spec:
      containers:
      - name: web-app
        image: myapp:v1.0
        ports:
        - containerPort: 8080
---
# Green deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
      version: green
  template:
    metadata:
      labels:
        app: web-app
        version: green
    spec:
      containers:
      - name: web-app
        image: myapp:v2.0
        ports:
        - containerPort: 8080
```

#### Canary Deployment with Argo Rollouts

```yaml
# canary-rollout.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: canary-rollout
spec:
  replicas: 10
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {}
      - setWeight: 40
      - pause: {duration: 10}
      - setWeight: 60
      - pause: {duration: 10}
      - setWeight: 80
      - pause: {duration: 10}
      canaryService: canary-service
      stableService: stable-service
      trafficRouting:
        alb:
          ingress: canary-ingress
          servicePort: 80
  selector:
    matchLabels:
      app: canary-app
  template:
    metadata:
      labels:
        app: canary-app
    spec:
      containers:
      - name: app
        image: myapp:latest
        ports:
        - containerPort: 8080
```

### StatefulSets for Stateful Applications

```yaml
# postgres-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-headless
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: myapp
        - name: POSTGRES_USER
          value: postgres
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        ports:
        - containerPort: 5432
          name: postgres
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        livenessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - exec pg_isready -U postgres -h 127.0.0.1 -p 5432
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - exec pg_isready -U postgres -h 127.0.0.1 -p 5432
          initialDelaySeconds: 5
          periodSeconds: 5
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
      storageClassName: gp3
---
# Headless service for StatefulSet
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
  - port: 5432
    name: postgres
```

### DaemonSets for Node-Level Services

```yaml
# logging-daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-logging
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: fluentd-logging
  template:
    metadata:
      labels:
        app: fluentd-logging
    spec:
      tolerations:
      # Allow running on master nodes
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      # Allow running on all nodes
      - operator: Exists
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1-debian-elasticsearch
        env:
        - name: FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch.logging.svc.cluster.local"
        - name: FLUENT_ELASTICSEARCH_PORT
          value: "9200"
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

### Jobs and CronJobs

#### One-time Jobs

```yaml
# database-migration-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: database-migration
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migration
        image: migrate/migrate
        command:
        - migrate
        - -path
        - /migrations
        - -database
        - postgres://user:pass@postgres:5432/db?sslmode=disable
        - up
        volumeMounts:
        - name: migration-scripts
          mountPath: /migrations
      volumes:
      - name: migration-scripts
        configMap:
          name: migration-scripts
  backoffLimit: 3
  activeDeadlineSeconds: 300
```

#### Scheduled Jobs (CronJobs)

```yaml
# backup-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: database-backup
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: backup
            image: postgres:13
            command:
            - /bin/bash
            - -c
            - |
              pg_dump -h postgres -U postgres myapp > /backup/backup-$(date +%Y%m%d-%H%M%S).sql
              aws s3 cp /backup/ s3://my-backups/database/ --recursive
            env:
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: password
            - name: AWS_ACCESS_KEY_ID
              valueFrom:
                secretKeyRef:
                  name: aws-credentials
                  key: access-key
            - name: AWS_SECRET_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: aws-credentials
                  key: secret-key
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          volumes:
          - name: backup-storage
            emptyDir: {}
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
```

---

## 7. Networking in EKS {#networking}

### Understanding Kubernetes Networking

#### The Four Networking Problems Kubernetes Solves

1. **Container-to-Container Communication**: Solved by Pod networking
2. **Pod-to-Pod Communication**: Solved by cluster networking
3. **Pod-to-Service Communication**: Solved by Services
4. **External-to-Service Communication**: Solved by Ingress

### EKS Networking Components

#### AWS VPC CNI Deep Dive

The AWS VPC CNI plugin provides several key capabilities:

**IP Address Management:**
```yaml
# vpc-cni-configuration.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: amazon-vpc-cni
  namespace: kube-system
data:
  # Enable prefix delegation for higher pod density
  enable-prefix-delegation: "true"
  
  # Pod ENI feature for network security
  enable-pod-eni: "true"
  
  # Network policy support
  enable-network-policy-controller: "true"
  
  # IP warmup settings
  warm-prefix-target: "1"
  warm-ip-target: "3"
  minimum-ip-target: "3"
  
  # ENI configuration label
  eni-config-label-def: "topology.kubernetes.io/zone"
```

**Pod Networking Flow:**
```
┌─────────────────────────────────────────────────┐
│                Worker Node                      │
│  ┌─────────────────────────────────────────┐   │
│  │              Pod Network                │   │
│  │                                         │   │
│  │  ┌─────────┐    ┌─────────┐           │   │
│  │  │  Pod A  │    │  Pod B  │           │   │
│  │  │10.0.1.5 │    │10.0.1.6 │           │   │
│  │  └─────────┘    └─────────┘           │   │
│  │       │              │                │   │
│  │  ┌────┴──────────────┴────┐           │   │
│  │  │     AWS VPC CNI        │           │   │
│  │  └────────┬───────────────┘           │   │
│  └───────────┼───────────────────────────────┘   │
│              │                                   │
│  ┌───────────┼───────────────────────────────┐   │
│  │          ENI (10.0.1.4)                  │   │
│  │     ┌─────┴─────┐                        │   │
│  │     │  IP Pool  │                        │   │
│  │     │10.0.1.5-20│                        │   │
│  │     └───────────┘                        │   │
│  └───────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

#### Service Types and Use Cases

**1. ClusterIP (Internal Communication)**
```yaml
# clusterip-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
```

**2. NodePort (Development/Testing)**
```yaml
# nodeport-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-nodeport
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080  # Optional: K8s will assign if not specified
```

**3. LoadBalancer (Production External Access)**
```yaml
# loadbalancer-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-lb
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "tcp"
spec:
  type: LoadBalancer
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
```

#### Advanced Load Balancer Configuration

**Application Load Balancer (ALB) with Ingress:**
```yaml
# alb-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-west-2:123456789012:certificate/abc123
    alb.ingress.kubernetes.io/tags: Environment=production,Team=platform
    
    # Health check configuration
    alb.ingress.kubernetes.io/healthcheck-path: /health
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '30'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
    alb.ingress.kubernetes.io/healthy-threshold-count: '2'
    alb.ingress.kubernetes.io/unhealthy-threshold-count: '3'
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
  - host: admin.myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 80
```

**Network Load Balancer (NLB) Configuration:**
```yaml
# nlb-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: high-performance-app
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    
    # Preserve client IP
    service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: preserve_client_ip.enabled=true
    
    # Health check configuration
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol: "HTTP"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: "/health"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval: "10"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-timeout: "6"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-healthy-threshold: "2"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-unhealthy-threshold: "2"
spec:
  type: LoadBalancer
  selector:
    app: high-performance-app
  ports:
  - port: 443
    targetPort: 8443
    protocol: TCP
    name: https
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
```

### Network Policies for Security

#### Basic Network Policies

```yaml
# default-deny-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
# Allow specific ingress traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
---
# Allow database access
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-db
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 5432
```

#### Advanced Network Policies

```yaml
# namespace-isolation.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: namespace-isolation
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Allow traffic from same namespace
  - from:
    - namespaceSelector:
        matchLabels:
          name: production
  # Allow traffic from monitoring namespace
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
      podSelector:
        matchLabels:
          app: prometheus
  egress:
  # Allow DNS resolution
  - to: []
    ports:
    - protocol: UDP
      port: 53
  # Allow traffic to same namespace
  - to:
    - namespaceSelector:
        matchLabels:
          name: production
  # Allow traffic to external services (AWS services)
  - to: []
    ports:
    - protocol: TCP
      port: 443
```

### Service Mesh with Istio

#### Installing Istio on EKS

```bash
# Download and install Istio
curl -L https://istio.io/downloadIstio | sh -
export PATH=$PWD/istio-1.19.0/bin:$PATH

# Install Istio control plane
istioctl install --set values.defaultRevision=default

# Enable automatic sidecar injection
kubectl label namespace default istio-injection=enabled
```

#### Istio Configuration Examples

```yaml
# istio-gateway.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: app-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - myapp.example.com
    tls:
      httpsRedirect: true
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: myapp-tls
    hosts:
    - myapp.example.com
---
# Virtual Service for traffic routing
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: app-virtualservice
spec:
  hosts:
  - myapp.example.com
  gateways:
  - app-gateway
  http:
  - match:
    - uri:
        prefix: /api/v2
    route:
    - destination:
        host: backend-v2
        port:
          number: 80
      weight: 20
    - destination:
        host: backend-v1
        port:
          number: 80
      weight: 80
    fault:
      delay:
        percentage:
          value: 0.1
        fixedDelay: 5s
  - match:
    - uri:
        prefix: /api
    route:
    - destination:
        host: backend-v1
        port:
          number: 80
  - route:
    - destination:
        host: frontend
        port:
          number: 80
```

#### Istio Security Policies

```yaml
# peer-authentication.yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT
---
# Authorization policy
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: backend-policy
  namespace: production
spec:
  selector:
    matchLabels:
      app: backend
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/production/sa/frontend"]
    to:
    - operation:
        methods: ["GET", "POST"]
        paths: ["/api/*"]
  - from:
    - source:
        principals: ["cluster.local/ns/monitoring/sa/prometheus"]
    to:
    - operation:
        methods: ["GET"]
        paths: ["/metrics"]
```

### DNS and Service Discovery

#### CoreDNS Configuration

```yaml
# coredns-custom-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
            lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
            ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf {
            max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
    # Custom domain forwarding
    company.internal:53 {
        errors
        cache 30
        forward . 10.0.0.100
    }
```

#### Service Discovery Examples

```yaml
# headless-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: database-headless
spec:
  clusterIP: None  # Headless service
  selector:
    app: database
  ports:
  - port: 5432
    name: postgres
---
# Service with custom DNS
apiVersion: v1
kind: Service
metadata:
  name: api-service
  annotations:
    service.alpha.kubernetes.io/tolerate-unready-endpoints: "true"
spec:
  selector:
    app: api
  ports:
  - port: 80
    targetPort: 8080
  # This creates DNS records:
  # api-service.default.svc.cluster.local
  # api-service.default.svc
  # api-service.default
  # api-service (from same namespace)
```

---

## 8. Security Best Practices {#security}

### Kubernetes Security Fundamentals

#### The 4C's of Cloud Native Security

1. **Cloud**: AWS security best practices
2. **Cluster**: Kubernetes cluster security
3. **Container**: Container image and runtime security
4. **Code**: Application security

### Authentication and Authorization

#### AWS IAM Integration with EKS

**EKS Cluster Authentication Flow:**
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   kubectl   │───▶│   AWS STS   │───▶│ EKS Cluster │
│             │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
```

#### RBAC (Role-Based Access Control)

```yaml
# Example Role for pod management
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: development
  name: pod-manager
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch", "create", "update", "delete"]

---
# RoleBinding to assign role to users/groups
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-manager-binding
  namespace: development
subjects:
- kind: User
  name: developer
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-manager
  apiGroup: rbac.authorization.k8s.io
```

### Network Security

#### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-traffic
spec:
  podSelector:
    matchLabels:
      app: secure-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          purpose: production
    ports:
    - protocol: TCP
      port: 80
```

### Pod Security

1. **Pod Security Standards**
   - Privileged
   - Baseline
   - Restricted

2. **Security Context**
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
```

### Container Image Security

1. **Image Scanning**
   - Amazon ECR scanning
   - Trivy integration
   - Vulnerability management

2. **Image Pull Policies**
   - Always use private registries
   - Implement image signing
   - Use image pull secrets

### Secrets Management

1. **AWS Secrets Manager Integration**
2. **External Secrets Operator**
3. **Sealed Secrets for GitOps**

---

## 9. Monitoring and Logging {#monitoring}

### CloudWatch Container Insights

#### Setup and Configuration

```yaml
# CloudWatch agent configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: cwagent-config
  namespace: amazon-cloudwatch
data:
  cwagentconfig.json: |
    {
      "logs": {
        "metrics_collected": {
          "kubernetes": {
            "cluster_name": "eks-cluster",
            "metrics_collection_interval": 60
          }
        }
      }
    }
```

### Prometheus and Grafana

1. **Installation using Helm**
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack
```

2. **Key Metrics to Monitor**
   - Node CPU/Memory usage
   - Pod resource utilization
   - Network throughput
   - API server latency

### Centralized Logging

#### Fluent Bit Setup

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-config
data:
  fluent-bit.conf: |
    [SERVICE]
        Flush          5
        Daemon        Off
        Log_Level     info

    [INPUT]
        Name          tail
        Path          /var/log/containers/*.log
        Parser        docker
        Tag           kube.*

    [OUTPUT]
        Name          cloudwatch
        Match         kube.*
        region        us-west-2
        log_group_name    /eks/cluster-name/logs
```

---

## 10. Cost Optimization {#cost-optimization}

### Resource Management

1. **Right-sizing Workloads**
   - Use Vertical Pod Autoscaling (VPA)
   - Implement Horizontal Pod Autoscaling (HPA)
   - Regular resource utilization review

2. **Node Group Optimization**
   - Mix of On-Demand and Spot instances
   - Proper instance type selection
   - Auto-scaling configuration

```yaml
# Example HPA configuration
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Cost Allocation

1. **Tagging Strategy**
2. **Namespace-based Cost Attribution**
3. **AWS Cost Explorer Integration**

### Storage Optimization

1. **EBS Volume Management**
2. **S3 Lifecycle Policies**
3. **EFS vs EBS Tradeoffs**

---

## 11. Production Best Practices {#production-practices}

### High Availability

1. **Multi-AZ Deployment**
   - Node groups across AZs
   - Control plane redundancy
   - Stateful workload distribution

2. **Backup and Disaster Recovery**
   - Velero implementation
   - Regular backup testing
   - Cross-region replication

### GitOps Implementation with GitLab CI

#### Project Structure
```
├── .gitlab-ci.yml
├── k8s/
│   ├── base/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── ingress.yaml
│   │   └── kustomization.yaml
│   └── overlays/
│       ├── development/
│       │   ├── kustomization.yaml
│       │   └── patches/
│       ├── staging/
│       │   ├── kustomization.yaml
│       │   └── patches/
│       └── production/
│           ├── kustomization.yaml
│           └── patches/
└── Dockerfile
```

#### Base Kustomization
```yaml
# k8s/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
  - ingress.yaml
```

#### Environment Overlay
```yaml
# k8s/overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - ../../base
namePrefix: prod-
namespace: production
patches:
  - path: patches/replicas.yaml
  - path: patches/resources.yaml
configMapGenerator:
  - name: app-config
    literals:
      - ENV=production
```

#### GitLab CI Configuration
```yaml
# .gitlab-ci.yml
variables:
  DOCKER_REGISTRY: ${CI_REGISTRY}
  DOCKER_IMAGE: ${CI_REGISTRY_IMAGE}
  KUBE_CONFIG: ${KUBE_CONFIG_DATA}

stages:
  - test
  - build
  - validate
  - deploy

.kube-context:
  before_script:
    - mkdir -p $HOME/.kube
    - echo "$KUBE_CONFIG" | base64 -d > $HOME/.kube/config
    - kubectl config use-context eks-cluster

test:
  stage: test
  image: python:3.9
  script:
    - pip install -r requirements.txt
    - python -m pytest tests/

build:
  stage: build
  image: docker:20.10.16
  services:
    - docker:20.10.16-dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $DOCKER_IMAGE:$CI_COMMIT_SHA .
    - docker push $DOCKER_IMAGE:$CI_COMMIT_SHA
    - |
      if [ "$CI_COMMIT_BRANCH" == "main" ]; then
        docker tag $DOCKER_IMAGE:$CI_COMMIT_SHA $DOCKER_IMAGE:latest
        docker push $DOCKER_IMAGE:latest
      fi

validate:
  stage: validate
  image: 
    name: bitnami/kubectl:latest
    entrypoint: [""]
  extends: .kube-context
  script:
    - |
      for env in development staging production; do
        kubectl kustomize k8s/overlays/$env > manifests-$env.yaml
        kubectl apply --dry-run=client -f manifests-$env.yaml
      done

.deploy-template:
  image:
    name: bitnami/kubectl:latest
    entrypoint: [""]
  extends: .kube-context
  script:
    - kubectl kustomize k8s/overlays/$CI_ENVIRONMENT_NAME > manifests.yaml
    - |
      if [ "$CI_ENVIRONMENT_NAME" == "production" ]; then
        # Production deployment with manual approval and canary
        kubectl apply -f manifests.yaml --prune -l environment=$CI_ENVIRONMENT_NAME
        # Wait for rollout
        kubectl rollout status deployment/prod-app -n production
      else
        # Dev/Staging direct deployment
        kubectl apply -f manifests.yaml --prune -l environment=$CI_ENVIRONMENT_NAME
      fi

deploy-dev:
  extends: .deploy-template
  stage: deploy
  environment:
    name: development
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"

deploy-staging:
  extends: .deploy-template
  stage: deploy
  environment:
    name: staging
  rules:
    - if: $CI_COMMIT_BRANCH == "staging"

deploy-prod:
  extends: .deploy-template
  stage: deploy
  environment:
    name: production
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual
```

#### Environment-Specific Patches
```yaml
# k8s/overlays/production/patches/replicas.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 3

# k8s/overlays/production/patches/resources.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  template:
    spec:
      containers:
        - name: app
          resources:
            requests:
              cpu: "500m"
              memory: "512Mi"
            limits:
              cpu: "1000m"
              memory: "1Gi"
```

#### GitLab CI/CD Variables Setup
1. **Required Variables**
   - `KUBE_CONFIG_DATA`: Base64 encoded kubeconfig
   - `CI_REGISTRY`: GitLab container registry URL
   - `CI_REGISTRY_USER`: Registry username
   - `CI_REGISTRY_PASSWORD`: Registry password

2. **Environment Variables**
   ```bash
   # Set variables in GitLab CI/CD settings
   KUBE_CONFIG_DATA=$(cat ~/.kube/config | base64 -w 0)
   ```

3. **Repository Secret Management**
   - Use GitLab CI/CD variables for sensitive data
   - Implement external secret management (AWS Secrets Manager/HashiCorp Vault)

#### Deployment Strategy
1. **Branch Strategy**
   - `develop` -> Development environment
   - `staging` -> Staging environment
   - `main` -> Production environment

2. **Deployment Flow**
   - Commit triggers pipeline
   - Tests and builds run
   - Manifests validated
   - Environment-specific deployment
   - Production requires manual approval

3. **Rollback Process**
   ```bash
   # Revert to previous version
   git revert $COMMIT_SHA
   git push origin main
   
   # Manual rollback
   kubectl rollout undo deployment/prod-app -n production
   ```

### Release Strategies

1. **Blue-Green Deployments**
2. **Canary Releases**
3. **Feature Flags**

---

## 12. Troubleshooting {#troubleshooting}

### Common Issues and Solutions

#### Pod Issues
```bash
# Check pod status
kubectl get pod <pod-name> -o yaml
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

#### Networking Issues
1. **DNS Resolution**
   ```bash
   kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -- /bin/bash
   ```

2. **Service Connectivity**
   ```bash
   kubectl port-forward svc/myapp 8080:80
   ```

### Performance Debugging

1. **Resource Bottlenecks**
   ```bash
   kubectl top pods
   kubectl top nodes
   ```

2. **Network Latency**
   ```bash
   kubectl exec -it <pod-name> -- ping <service-name>
   ```

### Control Plane Troubleshooting

1. **API Server Issues**
   - Check CloudWatch logs
   - Verify security group rules
   - Validate IAM roles

2. **Worker Node Problems**
   - Check node conditions
   - Verify kubelet status
   - Review system logs

### Common EKS-Specific Issues

#### Authentication and Authorization Issues
1. **aws-auth ConfigMap Problems**
   ```bash
   # Check aws-auth configmap
   kubectl get configmap aws-auth -n kube-system -o yaml
   
   # Common fix for aws-auth
   kubectl edit configmap aws-auth -n kube-system
   ```
   - Symptoms: Unable to access cluster, authorization errors
   - Solution: Verify IAM role mappings in aws-auth ConfigMap

2. **Token Expiration**
   ```bash
   # Update kubeconfig
   aws eks update-kubeconfig --name cluster-name --region region
   
   # Verify AWS credentials
   aws sts get-caller-identity
   ```
   - Symptoms: "Token expired" or "Unauthorized" errors
   - Solution: Refresh AWS credentials or update kubeconfig

#### Networking Issues
1. **CNI Plugin Problems**
   ```bash
   # Check CNI pods
   kubectl get pods -n kube-system | grep aws-node
   
   # View CNI logs
   kubectl logs -n kube-system $(kubectl get pods -n kube-system | grep aws-node | awk '{print $1}')
   
   # Verify CNI configuration
   kubectl describe daemonset aws-node -n kube-system
   ```
   - Symptoms: Pods stuck in ContainerCreating, network connectivity issues
   - Solution: Check CNI version, subnet IP availability

2. **Load Balancer Issues**
   ```bash
   # Check service events
   kubectl describe service my-service
   
   # Verify AWS Load Balancer Controller
   kubectl get pods -n kube-system | grep aws-load-balancer-controller
   
   # Check controller logs
   kubectl logs -n kube-system $(kubectl get pods -n kube-system | grep aws-load-balancer-controller | awk '{print $1}')
   ```
   - Symptoms: LoadBalancer service stuck in 'Pending'
   - Solutions:
     - Check IAM roles and policies
     - Verify subnet tags
     - Validate security group rules

#### Node Group Management
1. **Auto Scaling Issues**
   ```bash
   # Check cluster autoscaler logs
   kubectl logs -n kube-system -l app=cluster-autoscaler
   
   # Verify node group configuration
   aws eks describe-nodegroup --cluster-name cluster-name --nodegroup-name nodegroup-name
   ```
   - Symptoms: Nodes not scaling up/down as expected
   - Solutions:
     - Check ASG configuration
     - Verify capacity requirements
     - Review CA configuration

2. **Node Health Issues**
   ```bash
   # Check node status and conditions
   kubectl describe node <node-name>
   
   # View system logs
   kubectl debug node/<node-name> -it --image=busybox
   
   # Check kubelet status
   ssh ec2-user@node-ip "sudo systemctl status kubelet"
   ```
   - Common problems:
     - Disk pressure
     - Memory pressure
     - Network connectivity
     - Kubelet configuration

#### EKS Control Plane Issues
1. **API Server Endpoint Problems**
   ```bash
   # Verify endpoint connectivity
   curl -k api-server-endpoint
   
   # Check endpoint status
   aws eks describe-cluster --name cluster-name | grep endpoint
   ```
   - Symptoms: API server unreachable
   - Solutions:
     - Check VPC endpoints
     - Verify security groups
     - Validate network ACLs

2. **Add-on Issues**
   ```bash
   # List add-ons
   aws eks list-addons --cluster-name cluster-name
   
   # Check add-on status
   kubectl get pods -n kube-system
   
   # Update problematic add-on
   aws eks update-addon --cluster-name cluster-name --addon-name addon-name --addon-version version
   ```
   - Common add-on problems:
     - CoreDNS configuration
     - VPC CNI version mismatch
     - Kube-proxy updates

#### Resource Management Issues
1. **Pod Eviction Problems**
   ```bash
   # Check pod priority
   kubectl get pods -o custom-columns=NAME:.metadata.name,PRIORITY:.spec.priority
   
   # View node resource usage
   kubectl top nodes
   ```
   - Causes:
     - Resource constraints
     - Node draining
     - Priority preemption

2. **Image Pull Failures**
   ```bash
   # Check ECR authentication
   aws ecr get-login-password | docker login --username AWS --password-stdin account.dkr.ecr.region.amazonaws.com
   
   # Verify pod pull secrets
   kubectl get secrets | grep regcred
   ```
   - Common causes:
     - ECR authentication
     - Rate limiting
     - Invalid image tags