# Kind Development Cluster - AI Assistant Instructions

## Project Overview
This project provides a complete Kubernetes development environment using Kind (Kubernetes in Docker). It's designed to support local development and testing of Kubernetes applications, specifically configured for Argo Workflows and geospatial data processing workloads.

**Key Feature**: Automatic configuration of `host.docker.internal` DNS resolution, enabling pods to access services running on the host system.

## Architecture
- **Platform**: Kind (Kubernetes in Docker)
- **Container Runtime**: Docker
- **Kubernetes Version**: Latest stable
- **Storage**: Local persistent volumes
- **Registry**: Optional Docker registry proxy for caching

## Directory Structure
```
kind-dev-cluster/
├── kind-cluster.yaml              # Kind cluster configuration
├── kind.sh                        # Main cluster management script
├── README.md                      # Project documentation
├── toggle_container.sh            # Container lifecycle management
├── wait_until_pods_have_started.sh # Pod readiness checker
├── data/                          # Persistent data storage
│   ├── argo-workflow/             # Argo workflow data
│   │   ├── input/                 # Input data for workflows
│   │   └── output/                # Workflow execution results
│   ├── argo-workflow-input/       # Alternative input directory
│   ├── argo-workflow-output/      # Alternative output directory
│   └── argo-workflow-results/     # Results archive
├── docker-registry-proxy/         # Docker registry caching
│   ├── docker-compose.yml         # Registry proxy setup
│   ├── docker_mirror_cache/       # Cache storage
│   └── docker_mirror_certs/       # SSL certificates
├── templates/                     # Kubernetes resource templates
│   ├── ingress.yaml              # Ingress configuration
│   └── volumes.yaml              # PV/PVC definitions
└── workflows/                     # Sample workflows
    └── hello-world.yaml          # Basic workflow example
```

## Key Components

### Kind Cluster Configuration (`kind-cluster.yaml`)
- Single control-plane node setup
- Kubernetes v1.34.0 base image
- Port forwarding for services (80, 443)
- Volume mounts for persistent data storage
- Docker registry integration
- Ingress controller ready configuration

### Management Scripts

#### `kind.sh`
Main cluster management script:
- `./kind.sh` - Create/recreate the cluster with full setup
- Automatic Docker registry proxy configuration
- **Automatic host.docker.internal DNS configuration** via CoreDNS
- Installs and configures Argo Workflows, Kubernetes Dashboard, and Ingress Nginx
- Sets up persistent volumes and RBAC for workflows

#### `toggle_container.sh`
Container lifecycle management:
- Start/stop individual containers
- Manage container dependencies
- Handle graceful shutdowns

#### `wait_until_pods_have_started.sh`
Pod readiness checker:
- Waits for pods to reach Ready state
- Used in CI/CD pipelines
- Configurable timeout and namespace

## Host System Access

### host.docker.internal Configuration
The cluster automatically configures DNS resolution for `host.docker.internal`, enabling pods to access services running on the host system:

- **Automatic Setup**: The `kind.sh` script automatically detects the Docker network gateway IP and configures CoreDNS
- **DNS Resolution**: `host.docker.internal` resolves to the Docker network gateway (typically `172.26.0.1`)
- **Service Access**: Pods can access host services via `http://host.docker.internal:PORT`

### Host Service Access Examples

#### From Pods
```bash
# Test DNS resolution
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup host.docker.internal

# Test HTTP connection
kubectl run test-connection --image=curlimages/curl --rm -it --restart=Never -- curl http://host.docker.internal:8080
```

#### In Argo Workflows
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: host-service-example-
  namespace: argo
spec:
  serviceAccountName: workflow-user
  entrypoint: access-host-service
  templates:
  - name: access-host-service
    container:
      image: curlimages/curl:latest
      command: [curl]
      args: ["-X", "GET", "http://host.docker.internal:8080/api/endpoint"]
```

### Requirements for Host Services
- Host services must bind to `0.0.0.0:PORT` or the Docker network IP, not just `localhost`
- Firewall rules may need adjustment for access from Docker containers
- Services should be accessible from the Docker network range

### Data Persistence
The `data/` directory provides persistent storage across cluster restarts:

- **argo-workflow/**: Primary Argo Workflows data
  - `input/`: Source data for processing
  - `output/`: Workflow execution results organized by workflow name
- **argo-workflow-input/**: Alternative input location
- **argo-workflow-output/**: Alternative output location
- **argo-workflow-results/**: Archive of completed workflow results

### Docker Registry Proxy
Optional local Docker registry proxy for:
- Caching frequently used images
- Reducing external network dependency
- Speeding up image pulls
- Handling rate limits

## Kubernetes Resources

### Persistent Volumes
Defined in `templates/volumes.yaml`:
- Local storage backed by host directories
- Multiple PVCs for different use cases
- Proper access modes and storage classes

### Ingress Configuration
Defined in `templates/ingress.yaml`:
- Route external traffic to services
- SSL termination (if configured)
- Path-based routing rules

## Development Workflow

### Cluster Setup
1. Ensure Docker is running
2. Run `./kind.sh create` to create cluster
3. Wait for all pods to be ready
4. Apply necessary Kubernetes manifests
5. Verify connectivity and storage

### Data Management
- Place input data in `data/argo-workflow/input/`
- Workflow outputs appear in `data/argo-workflow/output/`
- Results are organized by workflow execution name
- Clean up old results periodically

### Troubleshooting
- Check cluster status: `kubectl get nodes`
- Verify storage: `kubectl get pv,pvc`
- Check pod logs: `kubectl logs <pod-name> -n <namespace>`
- Restart cluster if needed: `./kind.sh restart`

## Integration with Geoflow

This cluster is specifically configured to support the Geoflow project:
- Argo Workflows namespace and RBAC
- Persistent volumes for geospatial data
- Proper resource limits and quotas
- GDAL/OGR compatible storage setup

### Argo Workflows Integration
- Service accounts with proper permissions
- Persistent volume claims for workflow data
- Network policies (if required)
- Resource quotas and limits

## Best Practices

### Resource Management
1. Monitor cluster resource usage
2. Set appropriate resource limits
3. Use resource quotas for namespaces
4. Clean up completed workflows regularly

### Data Management
1. Organize input data by project/dataset
2. Archive old workflow results
3. Use meaningful naming conventions
4. Backup important datasets

### Security
1. Use proper RBAC configurations
2. Secure sensitive data with secrets
3. Network policies for isolation
4. Regular security updates

### Performance
1. Use local storage for development
2. Configure appropriate resource limits
3. Monitor and tune JVM settings
4. Use registry proxy to reduce pull times

## Common Operations

### Cluster Management
- Create: `./kind.sh`
- Status: `kubectl cluster-info`
- Pods: `kubectl get pods --all-namespaces`
- Logs: `kubectl logs -f <pod> -n <namespace>`
- Test host access: `kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup host.docker.internal`

### Storage Operations
- List PVs: `kubectl get pv`
- Check PVC usage: `kubectl get pvc -n argo`
- Clean data: `rm -rf data/argo-workflow/output/*`

### Argo Workflows
- Submit workflow: `argo submit -n argo workflow.yaml`
- List workflows: `argo list -n argo`
- Get logs: `argo logs -n argo <workflow-name>`
- Delete workflow: `argo delete -n argo <workflow-name>`

## Environment Variables
- `KUBECONFIG`: Points to kind cluster config
- `DOCKER_HOST`: Docker daemon connection
- `KIND_CLUSTER_NAME`: Cluster name (default: kind)

## Networking
- Cluster IP range: 10.244.0.0/16
- Service IP range: 10.96.0.0/12
- NodePort range: 30000-32767
- Host ports: 80, 443 (configurable)
- **host.docker.internal**: Automatically configured to resolve to Docker network gateway (e.g., 172.26.0.1)

## Limitations
- Local development only (not for production)
- Limited by host machine resources
- Single host networking
- No true high availability