# EKS Node Groups Information

## Cluster Details
- **Cluster Name**: ${cluster_name}
- **Region**: ${region}

## Node Groups

### General Purpose Node Group
- **Name**: general
- **Instance Types**: t3.medium, t3.large
- **Capacity Type**: ON_DEMAND
- **Min Size**: 1
- **Max Size**: 5
- **Desired Size**: 2
- **Disk Size**: 20 GB (gp3)
- **Labels**: Environment=${cluster_name}, NodeGroup=general
- **Taints**: None

### GPU Node Group
- **Name**: gpu
- **Instance Types**: g5.xlarge, g5.2xlarge, g5.4xlarge
- **Capacity Type**: ON_DEMAND
- **Min Size**: 0
- **Max Size**: 3
- **Desired Size**: 0 (scale up as needed)
- **Disk Size**: 50 GB (gp3)
- **Labels**: Environment=${cluster_name}, NodeGroup=gpu, accelerator=nvidia
- **Taints**: nvidia.com/gpu=true:NoSchedule

### Spot Node Group
- **Name**: spot
- **Instance Types**: t3.medium, t3.large, c6i.large, m6i.large
- **Capacity Type**: SPOT
- **Min Size**: 0
- **Max Size**: 5
- **Desired Size**: 0 (scale up as needed)
- **Disk Size**: 20 GB (gp3)
- **Labels**: Environment=${cluster_name}, NodeGroup=spot
- **Taints**: spot=true:NoSchedule

## Usage Examples

### Deploy to General Purpose Nodes
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: app
    image: nginx
  nodeSelector:
    NodeGroup: general
```

### Deploy to GPU Nodes
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-app
spec:
  containers:
  - name: gpu-app
    image: nvidia/cuda:11.0-base
    resources:
      limits:
        nvidia.com/gpu: 1
  tolerations:
  - key: nvidia.com/gpu
    operator: Equal
    value: "true"
    effect: NoSchedule
  nodeSelector:
    NodeGroup: gpu
```

### Deploy to Spot Nodes
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: spot-app
spec:
  containers:
  - name: app
    image: nginx
  tolerations:
  - key: spot
    operator: Equal
    value: "true"
    effect: NoSchedule
  nodeSelector:
    NodeGroup: spot
```

## Scaling

To scale node groups, you can use AWS CLI or the AWS Console:

```bash
# Scale general node group
aws eks update-nodegroup-config \
  --cluster-name ${cluster_name} \
  --nodegroup-name general \
  --scaling-config minSize=2,maxSize=10,desiredSize=5

# Scale GPU node group
aws eks update-nodegroup-config \
  --cluster-name ${cluster_name} \
  --nodegroup-name gpu \
  --scaling-config minSize=1,maxSize=5,desiredSize=2
```

## Monitoring

All node groups have detailed monitoring enabled. You can monitor them through:
- CloudWatch metrics
- EKS console
- kubectl commands

```bash
# Check node status
kubectl get nodes --show-labels

# Check node groups
kubectl get nodes -l NodeGroup=general
kubectl get nodes -l NodeGroup=gpu
kubectl get nodes -l NodeGroup=spot
``` 