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
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }
  
  spec {
    ### Explicitly set the ingress class name to alb
    ingress_class_name = "alb"
    
    tls {
      hosts       = ["jupyter-test-pkvrnvm.paas.dev.rafay-edge.net"]
      secret_name = "jupyter-test-notebook-tls-x-jupyter-test-x-vcluster-small"
    }
    
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
