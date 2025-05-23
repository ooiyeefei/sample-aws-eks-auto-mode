# Create the ingress-nginx namespace that Rafay expects
# resource "kubernetes_namespace" "ingress_nginx" {
#   provider = kubernetes.eks_cluster
#   
#   metadata {
#     name = "ingress-nginx"
#     labels = {
#       "app.kubernetes.io/name" = "ingress-nginx"
#       "app.kubernetes.io/part-of" = "ingress-nginx"
#     }
#   }
#   
#   depends_on = [module.eks]
# }

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

### Create a new ingress resource instead of patching Rafay's
resource "kubernetes_ingress_v1" "jupyter_alb_ingress" {
  provider = kubernetes.eks_cluster
  
  metadata {
    name      = "jupyter-alb-ingress"
    namespace = "vcluster-small"
    annotations = {
      ### CHANGED - Removed Rafay-specific annotations and kept only ALB-specific ones
      "alb.ingress.kubernetes.io/healthcheck-path"  = "/api"
      "alb.ingress.kubernetes.io/healthcheck-port"  = "8888"
      "alb.ingress.kubernetes.io/target-type"       = "ip"
      "alb.ingress.kubernetes.io/listen-ports"      = "[{\"HTTP\": 80}]"
      "alb.ingress.kubernetes.io/success-codes"     = "200-399"
      ### CHANGED - Added scheme annotation for internet-facing ALB
      "alb.ingress.kubernetes.io/scheme"            = "internet-facing"
    }
  }
  
  spec {
    ingress_class_name = "alb"
    
    ### CHANGED - Removed host-based routing to use ALB DNS directly
    rule {
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
  
  depends_on = [kubernetes_ingress_class_v1.alb]
}

### Output the ALB DNS name for easy access
output "jupyter_alb_dns" {
  description = "DNS name of the ALB for accessing Jupyter notebook"
  value       = kubernetes_ingress_v1.jupyter_alb_ingress.status[0].load_balancer[0].ingress[0].hostname
}

# Create a ConfigMap in the ingress-nginx namespace to help Rafay identify the ALB
# resource "kubernetes_config_map" "ingress_controller_info" {
#   provider = kubernetes.eks_cluster
#   
#   metadata {
#     name = "ingress-controller-info"
#     namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
#     labels = {
#       "app.kubernetes.io/part-of" = "ingress-nginx"
#       "rafay.dev/ingress-controller" = "true"
#     }
#   }
#   
#   data = {
#     "controller-type" = "eks-alb"
#     "ingress-class" = "alb"
#   }
#   
#   depends_on = [kubernetes_namespace.ingress_nginx]
# }

# data "external" "vcluster_service_name" {
#   program = ["bash", "-c", "kubectl get svc -n vcluster-small -o jsonpath='{\"service_name\": \"{.items[?(@.metadata.name==\"jupyter-test-notebook-x-jupyter-test-x-vcluster-small\")].metadata.name}\"}' 2>/dev/null || echo '{\"service_name\": \"jupyter-test-notebook-x-jupyter-test-x-vcluster-small\"}'"]
# }


# Patch the Rafay-created ingress to use ALB instead of NGINX
# resource "kubernetes_manifest" "patch_rafay_ingress" {
#   provider = kubernetes.eks_cluster
#   
#   manifest = {
#     apiVersion = "networking.k8s.io/v1"
#     kind       = "Ingress"
#     metadata = {
#       name      = "jupyter-test-notebook-x-jupyter-test-x-vcluster-small"
#       namespace = "vcluster-small"
#       annotations = {
#         "kubernetes.io/ingress.class"                 = "alb"
#         "alb.ingress.kubernetes.io/healthcheck-path"  = "/api/health"
#         "alb.ingress.kubernetes.io/healthcheck-port"  = "8888"
#         "alb.ingress.kubernetes.io/target-type"       = "ip"
#         "alb.ingress.kubernetes.io/listen-ports"      = "[{\"HTTP\": 80}]"
#         "alb.ingress.kubernetes.io/success-codes"     = "200-399,404"
#         "cert-manager.io/cluster-issuer"              = "letsencrypt-demo"
#         "kubernetes.io/tls-acme"                      = "true"
#         "nginx.ingress.kubernetes.io/proxy-body-size" = "50m"
#       }
#       labels = {
#         "vcluster.loft.sh/managed-by" = "vcluster-small"
#         "vcluster.loft.sh/namespace"  = "jupyter-test"
#       }
#     }
#     spec = {
#       ingressClassName = "alb"
#       rules = [{
#         host = "jupyter-test-pkvrnvm.paas.dev.rafay-edge.net"
#         http = {
#           paths = [{
#             path     = "/"
#             pathType = "Prefix"
#             backend = {
#               service = {
#                 name = data.external.vcluster_service_name.result.service_name
#                 port = {
#                   number = 8888
#                 }
#               }
#             }
#           }]
#         }
#       }]
#     }
#   }
# 
#   field_manager {
#     force_conflicts = true
#   }
#   
#   depends_on = [kubernetes_ingress_class_v1.alb]
# }
