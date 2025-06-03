# SearXNG Setup

> **🔍 Step 5 of 5**: This should be completed after LiteLLM setup is finished.

## Overview

This directory contains the configuration files for setting up SearXNG as a privacy-focused web search engine on EKS Auto Mode. SearXNG provides web search capabilities for OpenWebUI, enabling real-time web data integration with your AI chat interface.

## What is SearXNG?

SearXNG is a free internet metasearch engine that:
- **Aggregates results** from various search services and databases
- **Protects privacy** - users are neither tracked nor profiled
- **Provides JSON API** - perfect for AI integration
- **Supports 1000+ search engines** - comprehensive search coverage
- **Offers caching** - improved performance with Redis

## Architecture

SearXNG is deployed as a shared service with the following components:

- **SearXNG Engine**: Main metasearch service that aggregates results
- **Redis Cache**: Optional caching for improved search performance
- **Internal Service**: Kubernetes service for OpenWebUI communication
- **JSON API**: Optimized endpoint for AI integration

## Prerequisites

Before deploying SearXNG, ensure you have:

1. ✅ **Completed**: Main Terraform infrastructure deployment ([see main README](../README.md))
2. ✅ **Completed**: OpenWebUI setup ([see OpenWebUI README](../setup-openwebui/))
3. ✅ **Completed**: LiteLLM setup ([see LiteLLM README](../setup-litellm/))

## Deployment Steps

### 1. Navigate to SearXNG Directory

```bash
cd setup-searxng
```

### 2. Add SearXNG Helm Repository

```bash
# Add the SearXNG Helm repository
helm repo add searxng https://charts.searxng.org
helm repo update
```

### 3. Deploy SearXNG

```bash
# Deploy SearXNG with optimized configuration
helm install searxng searxng/searxng -f searxng-values.yaml -n vllm-inference
```

> **Note**: SearXNG is deployed in the same `vllm-inference` namespace as OpenWebUI and Tika for easy service discovery.

### 4. Verify Deployment

Check that SearXNG is running correctly:

```bash
# Check pods
kubectl get pods -n vllm-inference | grep searxng

# Check services
kubectl get svc -n vllm-inference | grep searxng

# Check SearXNG logs
kubectl logs deployment/searxng -n vllm-inference
```
## Configuration Details

### SearXNG Configuration

The `searxng-values.yaml` file includes optimized settings for OpenWebUI integration:

- **JSON Format Enabled**: Required for OpenWebUI API integration
- **Redis Caching**: Improved performance for repeated searches
- **Security Settings**: Hardened configuration for production use
- **Search Engines**: Optimized selection of search providers
- **Rate Limiting**: Configured to handle OpenWebUI requests

### OpenWebUI Integration

Once configured, OpenWebUI will:
- **Enable Web Search Toggle**: Users can turn web search on/off per conversation
- **Integrate Results**: Web search results are included in AI responses
- **Maintain Privacy**: No user tracking through SearXNG
- **Cache Results**: Redis caching improves response times

## Testing Web Search

### 1. Access OpenWebUI

Get your OpenWebUI URL:

```bash
# Get the OpenWebUI load balancer URL
export OPENWEBUI_URL=$(kubectl get service open-webui-service -n vllm-inference -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "OpenWebUI is available at: http://$OPENWEBUI_URL"
```

### 2. Enable Web Search in Chat

1. **Open OpenWebUI** in your browser
2. **Start a new chat** or open an existing conversation
3. **Click the "+" button** next to the message input field
4. **Toggle "Web Search" ON** - you should see it highlighted
5. **Ask a question** that requires current information (e.g., "What's the latest news about AI?")
6. **Verify results** - the AI response should include recent web search results

### 3. Test Different Queries

Try various types of searches to verify functionality:

```
Current Events: "What happened in the stock market today?"
Technical Info: "Latest Python 3.12 features"
Recent News: "Recent developments in renewable energy"
Factual Data: "Current population of Tokyo"
```

### 4. Verify Search Integration

You should see:
- ✅ **Web Search Toggle**: Available in chat interface
- ✅ **Enhanced Responses**: AI answers include web data
- ✅ **Current Information**: Up-to-date results from the web
- ✅ **Source Attribution**: References to web sources in responses

## Multi-Tenant Considerations

SearXNG is deployed as a **shared service** across all OpenWebUI tenants:

### Benefits:
- **Cost Effective**: Single SearXNG instance serves all tenants
- **Consistent Results**: Same search quality across all deployments
- **Simplified Management**: One service to maintain and update
- **Resource Efficient**: Shared caching and processing

### Configuration:
- **Same URL**: All tenants use `http://searxng.vllm-inference.svc.cluster.local:8080`
- **No Tenant Isolation**: Search results are not tenant-specific (appropriate for web search)
- **Shared Cache**: Redis cache benefits all tenants

### Multi-Tenant Setup:
If you're using the multi-tenant setup, ensure all tenant `values.yaml` files include the SearXNG environment variables.

## Performance Optimization

### Redis Caching

SearXNG is configured with Redis caching for:
- **Faster Responses**: Cached search results return immediately
- **Reduced Load**: Less load on external search engines
- **Better UX**: Improved response times for users

### Resource Limits

The deployment includes appropriate resource limits:
- **CPU**: Optimized for search processing
- **Memory**: Sufficient for caching and operations
- **Replicas**: Can be scaled based on usage

### Search Engine Selection

The configuration includes optimized search engines:
- **General Search**: Google, Bing, DuckDuckGo
- **Academic**: Google Scholar, Semantic Scholar
- **News**: Various news sources
- **Technical**: Stack Overflow, GitHub

## Security Considerations

### Privacy Protection
- **No User Tracking**: SearXNG doesn't track or profile users
- **No Data Retention**: Search queries are not stored
- **Anonymous Requests**: All searches are anonymous

### Network Security
- **Internal Only**: SearXNG is not exposed externally
- **Service Mesh**: Communication within Kubernetes cluster
- **No External Access**: Only accessible by OpenWebUI pods

### Configuration Security
- **Hardened Settings**: Security-focused configuration
- **Rate Limiting**: Protection against abuse
- **Resource Limits**: Prevents resource exhaustion

## Troubleshooting

### Common Issues

#### 1. Web Search Not Available in OpenWebUI

**Symptoms**: No web search toggle in chat interface

**Solutions**:
```bash
# Check OpenWebUI environment variables
kubectl describe deployment open-webui -n vllm-inference | grep -A 20 "Environment:"

# Verify SearXNG service is running
kubectl get svc searxng -n vllm-inference

# Check OpenWebUI logs
kubectl logs deployment/open-webui -n vllm-inference | grep -i search
```

#### 2. SearXNG Service Not Responding

**Symptoms**: Web search toggle available but no results

**Solutions**:
```bash
# Check SearXNG pod status
kubectl get pods -n vllm-inference | grep searxng

# Check SearXNG logs
kubectl logs deployment/searxng -n vllm-inference

# Test SearXNG directly
kubectl exec -it deployment/open-webui -n vllm-inference -- curl "http://searxng.vllm-inference.svc.cluster.local:8080/search?q=test&format=json"
```

#### 3. Slow Search Responses

**Symptoms**: Web search takes too long to respond

**Solutions**:
```bash
# Check Redis cache status
kubectl get pods -n vllm-inference | grep redis

# Monitor SearXNG performance
kubectl top pods -n vllm-inference | grep searxng

# Check resource usage
kubectl describe pod <searxng-pod-name> -n vllm-inference
```

### Debugging Commands

```bash
# Get all SearXNG resources
kubectl get all -n vllm-inference | grep searxng

# Check SearXNG configuration
kubectl get configmap -n vllm-inference | grep searxng

# View SearXNG service details
kubectl describe service searxng -n vllm-inference

# Check network connectivity
kubectl exec -it deployment/open-webui -n vllm-inference -- nslookup searxng.vllm-inference.svc.cluster.local
```

## Cleanup

To remove SearXNG:

```bash
# Remove SearXNG deployment
helm uninstall searxng -n vllm-inference

# Remove any remaining resources
kubectl delete all -l app.kubernetes.io/name=searxng -n vllm-inference
```

To disable web search in OpenWebUI without removing SearXNG:

```bash
# Update OpenWebUI to disable web search
helm upgrade open-webui open-webui/open-webui -f values.yaml -n vllm-inference --reuse-values --set extraEnvVars[0].name="ENABLE_RAG_WEB_SEARCH" --set extraEnvVars[0].value="False"
```

## Completion

🎉 **Setup Complete!** You now have a fully functional EKS Auto Mode AI platform with:

- **✅ Infrastructure**: EKS cluster with Auto Mode features
- **✅ Custom Branding**: GAR GPT branded OpenWebUI
- **✅ Document Processing**: S3 storage, PostgreSQL vectors, Apache Tika
- **✅ Multi-Provider LLM**: LiteLLM gateway with cost tracking
- **✅ Web Search**: SearXNG integration for real-time web data

### Your Complete AI Platform Features:

🤖 **AI Chat Interface**
- Custom GAR GPT branding
- Multi-provider LLM access
- Document upload and processing
- Real-time web search integration

📊 **Enterprise Features**
- Cost tracking and usage analytics
- Multi-tenant support
- Secure credential management
- Scalable infrastructure

🔒 **Security & Privacy**
- AWS Secrets Manager integration
- Pod Identity for secure access
- Privacy-focused web search
- No user tracking or profiling

🚀 **Production Ready**
- Auto-scaling with Karpenter
- Load balancer configuration
- Redis caching for performance
- Comprehensive monitoring

Your AI platform is now ready for production workloads with enterprise-grade security, scalability, cost optimization, and comprehensive AI capabilities including document processing and web search.

## Support

For issues and questions:
- Check the [SearXNG documentation](https://docs.searxng.org/)
- Review the [OpenWebUI web search guide](https://docs.openwebui.com/)
- Verify all prerequisites are met
- Follow the sequential setup flow
- Check troubleshooting steps above

## Next Steps

Consider these enhancements for your AI platform:
- **Monitoring**: Set up Prometheus and Grafana for comprehensive monitoring
- **Backup**: Implement automated backup strategies for databases
- **CI/CD**: Set up automated deployment pipelines
- **Custom Models**: Add additional LLM providers through LiteLLM
- **Advanced RAG**: Implement more sophisticated RAG pipelines
