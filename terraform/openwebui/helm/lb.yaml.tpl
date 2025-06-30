apiVersion: v1
kind: Service
metadata:
  name: open-webui-service
  namespace: ${namespace}
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    service.beta.kubernetes.io/aws-load-balancer-security-groups: "${node_security_group_id}"
spec:
  selector:
    app.kubernetes.io/component: open-webui
    app.kubernetes.io/instance: openwebui
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
