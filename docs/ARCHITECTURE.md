# Architecture Overview

This document describes the architecture of the AKS cluster with Cilium deployment.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Cloud                               │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Resource Group                             │ │
│  │                                                          │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │         Virtual Network (10.0.0.0/16)            │  │ │
│  │  │                                                    │  │ │
│  │  │  ┌──────────────────────────────────────────┐    │  │ │
│  │  │  │   AKS Cluster with Cilium CNI            │    │  │ │
│  │  │  │                                            │    │  │ │
│  │  │  │  ┌──────────────────────────────────┐    │    │  │ │
│  │  │  │  │  System Node Pool (3 nodes)     │    │    │  │ │
│  │  │  │  │  - Cilium Agents                 │    │    │  │ │
│  │  │  │  │  - Monitoring Stack              │    │    │  │ │
│  │  │  │  │  - OPA Gatekeeper                │    │    │  │ │
│  │  │  │  └──────────────────────────────────┘    │    │  │ │
│  │  │  │                                            │    │  │ │
│  │  │  │  ┌──────────────────────────────────┐    │    │  │ │
│  │  │  │  │  Application Workloads           │    │    │  │ │
│  │  │  │  │  - Frontend                       │    │    │  │ │
│  │  │  │  │  - Backend                        │    │    │  │ │
│  │  │  │  │  - Database                       │    │    │  │ │
│  │  │  │  └──────────────────────────────────┘    │    │  │ │
│  │  │  └──────────────────────────────────────────┘    │  │ │
│  │  └──────────────────────────────────────────────────┘  │ │
│  │                                                          │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │      Log Analytics Workspace                     │  │ │
│  │  │      - Container Insights                        │  │ │
│  │  │      - Metrics & Logs                            │  │ │
│  │  └──────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Azure Kubernetes Service (AKS)

**Purpose**: Managed Kubernetes cluster

**Key Features**:
- Kubernetes version: 1.28+
- Auto-upgrade enabled (stable channel)
- OIDC & Workload Identity enabled
- Azure Policy integration
- Managed identity authentication

**Node Pools**:
- **System Pool**: 
  - VM Size: Standard_D4s_v3 (4 vCPU, 16GB RAM)
  - Count: 2-5 nodes (auto-scaling enabled)
  - Purpose: System components, monitoring, policies

### 2. Cilium CNI

**Purpose**: eBPF-based networking and security

**Key Capabilities**:
- Network plugin: `none` (Cilium replaces default)
- Network policy: `cilium`
- Network dataplane: `cilium` (eBPF)
- Layer 3-7 network policies
- Hubble observability
- Service mesh capabilities

**Components**:
- Cilium Agent (DaemonSet on each node)
- Cilium Operator
- Hubble Relay
- Hubble UI

### 3. Monitoring Stack

**Purpose**: Observability and metrics collection

**Components**:

#### Prometheus
- **Version**: kube-prometheus-stack 55.0.0
- **Purpose**: Metrics collection and alerting
- **Storage**: 50Gi PersistentVolume
- **Retention**: 7 days
- **Scrape Targets**:
  - Kubernetes metrics
  - Cilium agent metrics
  - Hubble metrics
  - Node exporter
  - Kube-state-metrics

#### Grafana
- **Purpose**: Visualization and dashboards
- **Storage**: 10Gi PersistentVolume
- **Default Dashboards**:
  - Cilium metrics
  - Kubernetes cluster overview
  - Node metrics
  - Pod metrics

#### Alertmanager
- **Purpose**: Alert routing and notification
- **Configuration**: Default rules for K8s and Cilium

#### Azure Monitor
- **Purpose**: Native Azure monitoring
- **Features**:
  - Container Insights
  - Live logs
  - Performance metrics
  - Recommended alerts

### 4. OPA Gatekeeper

**Purpose**: Policy enforcement and compliance

**Configuration**:
- **Replicas**: 3
- **Audit Interval**: 60 seconds
- **Constraint Templates**:
  - Required labels
  - Allowed container registries
  - Resource limits enforcement
  - Privileged container blocking

**Enforcement Modes**:
- `deny`: Block non-compliant resources
- `dryrun`: Audit without blocking
- `warn`: Warning without blocking

### 5. Networking

**Virtual Network**:
- **Address Space**: 10.0.0.0/16
- **AKS Subnet**: 10.0.1.0/24

**Service CIDR**: 10.1.0.0/16
**DNS Service IP**: 10.1.0.10

**Load Balancer**: Standard SKU

**Network Policies**:
- Default deny all traffic
- Selective allow rules
- L7 HTTP filtering
- FQDN-based egress control

### 6. Security

**Identity**:
- User-assigned managed identity for AKS
- Workload identity for pods
- OIDC issuer enabled

**Secrets Management**:
- Key Vault Secrets Provider
- Secret rotation: 2 minutes

**Network Security**:
- Cilium network policies
- OPA Gatekeeper constraints
- Azure Policy integration

**Pod Security**:
- No privileged containers (enforced)
- Resource limits required (enforced)
- Read-only root filesystem (recommended)

## Data Flows

### 1. Application Traffic Flow

```
User → Load Balancer → Ingress → Frontend Pod
                                      ↓
                            (Cilium Policy Check)
                                      ↓
                                  Backend Pod
                                      ↓
                            (Cilium Policy Check)
                                      ↓
                                 Database Pod
```

### 2. Monitoring Data Flow

```
Application Pods → Metrics Endpoint
                        ↓
                   Prometheus (scrape)
                        ↓
                   Time-series DB
                        ↓
                    Grafana (query)
                        ↓
                  Visualization
                        
                        ↓
                Azure Monitor (optional)
                        ↓
                  Azure Portal
```

### 3. Policy Enforcement Flow

```
kubectl apply → API Server
                    ↓
            Gatekeeper Webhook
                    ↓
         Constraint Evaluation
                ↓         ↓
             Allow      Deny
                ↓         ↓
          Create Pod   Reject
```

### 4. Network Policy Flow

```
Pod A → Pod B (attempt)
           ↓
    Cilium Agent (eBPF)
           ↓
    Policy Evaluation
      ↓           ↓
    Allow       Deny
      ↓           ↓
   Forward     Drop
                  ↓
            Hubble Observe
```

## Scalability

### Auto-Scaling

**Horizontal Pod Autoscaler (HPA)**:
- Based on CPU/Memory metrics
- Custom metrics via Prometheus

**Cluster Autoscaler**:
- Min nodes: 2
- Max nodes: 5
- Scale based on pending pods

**Vertical Pod Autoscaler (VPA)**:
- Not deployed by default
- Can be added separately

### Performance

**Cilium eBPF**:
- Kernel-level packet processing
- Lower latency than iptables
- Better performance at scale

**Resource Allocation**:
- System pods: Guaranteed resources
- Application pods: Burstable/Best-effort

## High Availability

**Control Plane**:
- Managed by Azure (SLA: 99.95%)
- Multi-zone by default

**Nodes**:
- Minimum 2 nodes
- Spread across availability zones
- Auto-repair enabled

**Monitoring**:
- Prometheus: 1 replica (can increase)
- Grafana: 1 replica (stateful)
- Alert manager: 1 replica

**Gatekeeper**:
- 3 replicas for high availability
- Anti-affinity for distribution

## Disaster Recovery

**Backup Strategy**:
- Cluster configuration: Terraform state
- Application manifests: Git repository
- Persistent data: Azure Backup
- Monitoring data: 7-day retention

**Recovery Steps**:
1. Re-deploy cluster via Terraform
2. Apply application manifests
3. Restore persistent volumes
4. Verify monitoring and policies

## Cost Optimization

**Compute**:
- Standard_D4s_v3: ~$200/month per node
- 3 nodes: ~$600/month
- Auto-scaling: ~$400-$1000/month

**Storage**:
- Managed disks: ~$5-20/month
- Prometheus PV: ~$5/month
- Grafana PV: ~$1/month

**Networking**:
- Standard load balancer: ~$20/month
- Egress traffic: Variable

**Monitoring**:
- Log Analytics: Pay-per-GB ingested
- Container Insights: ~$50-100/month

**Total Estimated Cost**: ~$700-1200/month

## Best Practices Applied

1. ✅ **Network Policies**: Default deny, selective allow
2. ✅ **Resource Limits**: Enforced via Gatekeeper
3. ✅ **Monitoring**: Multi-layer observability
4. ✅ **Security**: Managed identity, no privileged containers
5. ✅ **IaC**: All infrastructure as Terraform code
6. ✅ **Auto-scaling**: Cluster and pod autoscaling
7. ✅ **High Availability**: Multiple replicas, zones
8. ✅ **Policy Enforcement**: OPA Gatekeeper integration

## Future Enhancements

Potential additions:
- Service Mesh (Istio/Linkerd integration with Cilium)
- GitOps (ArgoCD/Flux)
- Certificate Management (cert-manager)
- External Secrets Operator
- Backup solution (Velero)
- Multi-cluster federation
- Advanced threat detection
