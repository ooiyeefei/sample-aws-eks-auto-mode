# Create the ingress-nginx namespace that Rafay expects
resource "kubernetes_namespace" "ingress_nginx" {
  provider = kubernetes.eks_cluster
  
  metadata {
    name = "ingress-nginx"
    labels = {
      "app.kubernetes.io/name" = "ingress-nginx"
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
  
  depends_on = [module.eks]
}

# Create IngressClassParams for AWS ALB
resource "kubernetes_manifest" "ingress_class_params" {
  provider = kubernetes.eks_cluster
  
  manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "IngressClassParams"
    metadata = {
      name = "alb"
    }
    spec = {
      scheme = "internet-facing"
    }
  }
  
  depends_on = [module.eks]
}

# Create IngressClass for EKS Auto Mode's built-in ALB controller
resource "kubernetes_ingress_class_v1" "alb" {
  provider = kubernetes.eks_cluster
  
  metadata {
    name = "alb"
    annotations = {
      "ingressclass.kubernetes.io/is-default-class" = "true"
    }
  }
  
  spec {
    controller = "eks.amazonaws.com/alb"
    parameters {
      api_group = "eks.amazonaws.com"
      kind      = "IngressClassParams"
      name      = "alb"
    }
  }
  
  depends_on = [kubernetes_manifest.ingress_class_params]
}

# Create a ConfigMap in the ingress-nginx namespace to help Rafay identify the ALB
resource "kubernetes_config_map" "ingress_controller_info" {
  provider = kubernetes.eks_cluster
  
  metadata {
    name = "ingress-controller-info"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    labels = {
      "app.kubernetes.io/part-of" = "ingress-nginx"
      "rafay.dev/ingress-controller" = "true"
    }
  }
  
  data = {
    "controller-type" = "eks-alb"
    "ingress-class" = "alb"
  }
  
  depends_on = [kubernetes_namespace.ingress_nginx]
}

resource "kubernetes_ingress_v1" "jupyter_ingress" {
  provider = kubernetes.eks_cluster
  
  metadata {
    name      = "jupyter-ingress"
    namespace = "vcluster-small"
    annotations = {
      # Health check settings for the ALB
      "alb.ingress.kubernetes.io/healthcheck-port": "8888",
      "alb.ingress.kubernetes.io/healthcheck-path": "/api/health",
      "alb.ingress.kubernetes.io/healthcheck-protocol": "HTTP",
      "alb.ingress.kubernetes.io/success-codes": "200-399",
      "alb.ingress.kubernetes.io/target-type": "ip",
      
      # TLS and security settings - modified for HTTP only
      "alb.ingress.kubernetes.io/listen-ports": "[{\"HTTP\": 80}]",
      # Removed SSL redirect
      
      # Optional: increase timeout for Jupyter operations
      "alb.ingress.kubernetes.io/load-balancer-attributes": "idle_timeout.timeout_seconds=600"
    }
  }
  
  spec {
    ### Explicitly set the ingress class name to alb
    ingress_class_name = "alb"
    
    rule {
      host = "jupyter-test-pkvrnvm.paas.dev.rafay-edge.net"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "jupyter-test-notebook-x-jupyter-test-x-vcluster-small"
              port {
                number = 8888
              }
            }
          }
        }
      }
    }
  }
  
  depends_on = [kubernetes_ingress_class_v1.alb, kubernetes_namespace.ingress_nginx]
}
