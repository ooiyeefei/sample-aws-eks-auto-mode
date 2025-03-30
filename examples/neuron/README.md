# Neuron Workloads on EKS Auto Mode

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Implementation Steps](#implementation-steps)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)

## Overview
[AWS Inferentia2](https://aws.amazon.com/machine-learning/inferentia/) accelerates machine learning inference workloads with custom-built chips. Key benefits include:

🚀 **High Performance Inference**
- Purpose-built ML acceleration
- Optimized for transformer models
- Cost-effective alternative to GPUs

🎯 **ML Model Support**
- Supports popular ML frameworks
- Optimized for transformer architectures

This example demonstrates deploying Whisper Large V3 Turbo (OpenAI's speech recognition model) on EKS Auto Mode using Inferentia2 acceleration.

## Architecture
This example showcases Inferentia2-accelerated workloads using the following components:

### 🖥️ Instance Types
- **Default**: inf2 instances (optimized for ML inference)
- **Customization**: Available in [neuron-nodepool.yaml.tpl](../../nodepool-templates/neuron-nodepool.yaml.tpl)

### 🔧 Key Components
📦 **Infrastructure**
- NodePool and NodeClass for Neuron workload management
- Network Load Balancer for external access
- Persistent storage for compiled models

🧠 **ML Components**
- Model compilation job for Neuron optimization
- FastAPI inference service (uses 1 Neuron core)
- Gradio web UI for audio input
- Sample audio file for testing

## Implementation Steps

### 1. Setup EKS Auto Mode Cluster
Deploy the cluster using Terraform:
```bash
cd EKS-Auto-Mode/terraform
terraform init
terraform apply -auto-approve
$(terraform output -raw configure_kubectl)
```

### 2. Deploy Neuron NodePool
Deploy the NodePool that will manage our Inferentia2 instances:

```bash
cd ../nodepools
kubectl apply -f neuron-nodepool.yaml
```

> ⚠️ The Neuron NodePool applies the following taint to ensure only Neuron-compatible workloads are scheduled on these nodes:
>
> ```yaml
> taints:
>   - key: "aws.amazon.com/neuron"
>     value: "true"
>     effect: "NoSchedule"   # Prevents non-Neuron pods from scheduling
> ```
>
> Any pods that need to run on Neuron nodes must include matching tolerations in their specifications.

### 3. Deploy Storage and Components

1. **Create Persistent Storage**:
```bash
cd ../examples/neuron
kubectl apply -f pvc.yaml
```

2. **Run Model Compilation**:
```bash
kubectl apply -f whisper-compile.yaml
```

> 📝 The compilation job will:
> - Download Whisper Large V3 Turbo model
> - Compile for Neuron acceleration
> - Save compiled models to persistent storage
> - Takes approximately 10-15 minutes

To check if compilation over:
```bash
if kubectl logs $(kubectl get pods -l app=whisper-compile -n whisper-neuron -o name) -n whisper-neuron| grep -q "Compilation complete! Models saved to PVC."; then
  echo "Compilation is complete"
else
  echo "Compilation is still running"
fi
```

Once you see "Compilation is complete":
```bash
kubectl delete -f whisper-compile.yaml
```

3. **Deploy Inference Service**:
```bash
kubectl apply -f whisper-service.yaml
```

4. **Deploy Web UI**:
```bash
kubectl apply -f whisper-gradio-ui.yaml
```

> ⚠️ **Security Note**: The default configuration creates a public endpoint. To restrict access to your IP:
>
> 1. Get your IP:
> ```bash
> MY_IP=$(curl -s https://checkip.amazonaws.com)
> echo "Your IP address is: $MY_IP"
> ```
>
> 2. Add to whisper-gradio-ui.yaml:
> ```yaml
> spec:
>   loadBalancerSourceRanges:
>     - "${MY_IP}/32"
> ```
>
> 3. Apply changes:
> ```bash
> kubectl apply -f whisper-gradio-ui.yaml
> ```

### 4. Access the Application

1. **Get the UI Service URL**:
```bash
kubectl get service -n whisper-neuron whisper-gradio-service \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

2. Open the URL in your browser to start transcribing! 🎤

### 5. Using the Application

Choose your input method:
- Upload a WAV file
- Record directly from your microphone
- For testing, use the provided sample file in `samples/turbo-test.wav`

The audio will be sent to the inference service running on 1 Neuron core, and transcription results will be displayed in the UI.

> 💡 **Note**: The first transcription request may take up to 30 seconds for model warmup. Subsequent transcriptions will be much faster.

#### Microphone Recording Notes

If you're unable to record audio in Chrome, this is likely because Chrome blocks recording from insecure origins (HTTP). You have two options:

1. Use the file upload option instead of recording (recommended)
2. Enable insecure recording in Chrome (use with caution):
   - Go to chrome://flags/#unsafely-treat-insecure-origin-as-secure (copy this in search bar)
   - Add your LoadBalancer URL to the list
   - Restart Chrome

⚠️ WARNING: Enabling insecure recording reduces browser security. Only do this for testing purposes and only if you trust the network and deployment environment.


## Cleanup

🧹 Follow these steps to clean up all resources:

### 1. Remove Kubernetes Resources
First, remove the application components and node pool:

```bash
# Remove application components
kubectl delete -f whisper-gradio-ui.yaml
kubectl delete -f whisper-service.yaml
kubectl delete -f pvc.yaml

# Remove Neuron node pool
kubectl delete -f ../../nodepools/neuron-nodepool.yaml
```

### 2. Remove Cluster (Optional)
If you're done with the entire cluster:

```bash
cd ../../terraform
terraform destroy --auto-approve
```

## Troubleshooting

🔧 Common issues and their solutions:

### 🎯 Model Compilation Issues
1. **Compilation Job Status**
   - Check job status:
     ```bash
     kubectl get jobs
     ```
   - View compilation logs:
     ```bash
     kubectl logs job/whisper-model-compile
     ```

2. **Storage Issues**
   - Verify PVC is bound:
     ```bash
     kubectl get pvc model-storage-claim
     ```
   - Check storage class:
     ```bash
     kubectl get storageclass model-storage-class
     ```

### 🎤 Inference Service Issues
1. **Pod Status**
   - Check pod health:
     ```bash
     kubectl get pods -l app=whisper-inference
     ```
   - View service logs:
     ```bash
     kubectl logs -l app=whisper-inference
     ```

2. **Model Loading**
   - Verify models exist in storage
   - Check Neuron runtime status:
     ```bash
     kubectl exec -it <pod-name> -- neuron-ls
     ```

### 💻 Resource Constraints
1. **Neuron Capacity**
   - Ensure sufficient inf2 quota in your AWS account
   - Monitor Neuron utilization:
     ```bash
     kubectl describe node <node-name>
     ```
   - Check pod scheduling events:
     ```bash
     kubectl get events
     ```
