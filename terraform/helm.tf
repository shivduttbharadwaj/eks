# AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.0"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller.arn
  }

  depends_on = [
    module.eks
  ]
}

# Cluster Autoscaler
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.29.0"

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.eks.cluster_autoscaler_iam_role_arn
  }

  depends_on = [
    module.eks
  ]
}

# Metrics Server
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.11.0"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  depends_on = [
    module.eks
  ]
}

# Prometheus and Grafana
resource "helm_release" "prometheus_stack" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  create_namespace = true
  version    = "51.0.0"

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  depends_on = [
    module.eks
  ]
}

# AWS CloudWatch Agent
resource "helm_release" "cloudwatch_agent" {
  name       = "cloudwatch-agent"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-cloudwatch-metrics"
  namespace  = "amazon-cloudwatch"
  create_namespace = true
  version    = "0.0.9"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  depends_on = [
    module.eks
  ]
}

# Fluent Bit
resource "helm_release" "fluent_bit" {
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  namespace  = "logging"
  create_namespace = true
  version    = "0.34.0"

  values = [
    templatefile("${path.module}/templates/fluent-bit-values.yaml", {
      cluster_name = var.cluster_name
      region      = var.aws_region
    })
  ]

  depends_on = [
    module.eks
  ]
}
