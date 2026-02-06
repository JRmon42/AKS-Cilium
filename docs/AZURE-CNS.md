# Azure CNS (Container Networking Service) with Cilium

This document explains the Azure CNS configuration used in this AKS deployment and its benefits.

## What is Azure CNS?

**Azure Container Networking Service (CNS)** is Microsoft's overlay networking solution for AKS that separates pod IP addresses from the VNet address space. When combined with Cilium as the dataplane, it provides advanced networking capabilities with scalability and flexibility.

## Configuration

### Network Architecture

```
┌─────────────────────────────────────────────────────┐
│                  AKS Cluster                         │
│                                                       │
│  ┌──────────────────────────────────────────────┐   │
│  │          Azure CNS Overlay Network           │   │
│  │                                               │   │
│  │  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐    │   │
│  │  │ Pod  │  │ Pod  │  │ Pod  │  │ Pod  │    │   │
│  │  │10.244│  │10.244│  │10.244│  │10.244│    │   │
│  │  │.x.x  │  │.x.x  │  │.x.x  │  │.x.x  │    │   │
│  │  └──▲───┘  └──▲───┘  └──▲───┘  └──▲───┘    │   │
│  │     │         │         │         │          │   │
│  │  ┌──┴─────────┴─────────┴─────────┴──────┐  │   │
│  │  │      Cilium eBPF Dataplane            │  │   │
│  │  │  (Network Policies, L7 filtering)     │  │   │
│  │  └────────────────┬──────────────────────┘  │   │
│  └───────────────────┼─────────────────────────┘   │
│                      │                              │
│  ┌───────────────────┼─────────────────────────┐   │
│  │        Azure CNI Plugin                     │   │
│  └───────────────────┼─────────────────────────┘   │
└────────────────────── ┼──────────────────────────────┘
                        │
        ┌───────────────┴────────────────┐
        │   Azure Virtual Network        │
        │   VNet: 10.0.0.0/16           │
        │   Subnet: 10.0.1.0/24         │
        └────────────────────────────────┘
```

### Current Settings

This deployment uses the following networking configuration:

| Component | Value | Description |
|-----------|-------|-------------|
| **Network Plugin** | `azure` | Azure CNI for VNet integration |
| **Plugin Mode** | `overlay` | Azure CNS overlay networking |
| **Dataplane** | `cilium` | Cilium eBPF for packet processing |
| **Service CIDR** | `10.1.0.0/16` | IP range for Kubernetes services |
| **DNS Service IP** | `10.1.0.10` | IP address of kube-dns/CoreDNS |
| **Pod CIDR** | Managed by CNS | Automatically assigned by Azure CNS |
| **VNet CIDR** | `10.0.0.0/16` | Virtual network address space |
| **Subnet CIDR** | `10.0.1.0/24` | AKS node subnet |

## Benefits of Azure CNS Overlay

### 1. **Scalability**
- **No subnet IP exhaustion**: Pod IPs don't consume VNet IP addresses
- **Large clusters**: Support for significantly more pods per cluster
- **Flexible pod density**: No need to pre-calculate subnet sizes based on max pods

### 2. **Network Isolation**
- **Secure by default**: Pod network isolated from VNet
- **Reduced blast radius**: Network issues contained to overlay
- **Simplified security**: Easier to apply security controls

### 3. **Cost Optimization**
- **Reduced IP usage**: Smaller VNet address spaces needed
- **Efficient routing**: Fewer UDRs (User Defined Routes) required
- **Lower complexity**: Simplified network topology

### 4. **Operational Benefits**
- **Faster deployments**: No wait for VNet IP allocation
- **Easy scaling**: Add nodes without subnet resizing
- **Multi-cluster**: Multiple clusters can share the same VNet

## Cilium eBPF Dataplane Features

The Cilium dataplane provides advanced networking capabilities:

### 1. **High Performance**
- **eBPF acceleration**: In-kernel packet processing
- **Zero-copy**: Direct data path without context switches
- **Lower latency**: Reduced network overhead

### 2. **Advanced Network Policies**
- **Layer 7 filtering**: HTTP, gRPC, Kafka protocol awareness
- **DNS-based policies**: Allow/deny based on domain names
- **FQDN filtering**: External service access control
- **Identity-based**: Policies based on pod labels, not IPs

### 3. **Observability**
- **Hubble**: Real-time network flow visibility
- **Service map**: Visual representation of service dependencies
- **Network metrics**: Detailed performance and security metrics
- **Flow logs**: Comprehensive network activity logging

### 4. **Security**
- **mTLS**: Transparent mutual TLS between services
- **Network segmentation**: Microsegmentation with fine-grained control
- **Threat detection**: Anomaly detection and security monitoring
- **Compliance**: Meet regulatory requirements with policy enforcement

## How It Works

### Pod to Pod Communication (Same Node)

```
Pod A → Cilium eBPF → Pod B
```

- Direct communication via eBPF
- Network policies enforced in kernel
- Lowest latency path

### Pod to Pod Communication (Different Nodes)

```
Pod A → Cilium eBPF → Azure CNS Overlay → Cilium eBPF → Pod B
```

- Encapsulated via VXLAN or Geneve
- Routed through Azure SDN
- Network policies enforced at both ends

### Pod to External Communication

```
Pod → Cilium eBPF → Azure CNS → VNet → Internet/Azure Services
```

- NAT applied by Azure CNS
- Egress through node IP or LoadBalancer
- Network policies enforced on egress

## Verifying CNS Configuration

### Check Network Plugin

```bash
kubectl get ds -n kube-system | grep cilium
# Should show cilium daemonset running
```

### Check CNS Pods

```bash
kubectl get pods -n kube-system -l k8s-app=azure-cns
# Should show CNS pods (if using CNS directly)
```

### Verify Cilium Status

```bash
cilium status
```

**Expected output:**
```
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    disabled (using eBPF)
 \__/¯¯\__/    Hubble Relay:       OK
    \__/       ClusterMesh:        disabled

DaemonSet              cilium             Desired: 3, Ready: 3/3, Available: 3/3
Deployment             cilium-operator    Desired: 2, Ready: 2/2, Available: 2/2
Deployment             hubble-relay       Desired: 1, Ready: 1/1, Available: 1/1
Containers:            cilium             Running: 3
                       cilium-operator    Running: 2
                       hubble-relay       Running: 1
```

### Check Pod Networking

```bash
# Deploy a test pod
kubectl run test-pod --image=nginx --labels=app=test

# Check pod IP (should be from overlay network)
kubectl get pod test-pod -o jsonpath='{.status.podIP}'

# Verify network connectivity
kubectl exec test-pod -- curl -s http://kubernetes.default.svc.cluster.local
```

### View Network Configuration in Portal

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your AKS cluster
3. Go to **Settings** → **Networking**
4. Verify settings:
   - Network plugin: Azure
   - Network policy: Azure (Cilium)
   - Network mode: Overlay

## Limitations and Considerations

### Current Limitations

1. **No direct pod access from VNet**: Pods are not directly routable from VNet
2. **LoadBalancer required**: External access requires LoadBalancer service
3. **No network policy for Windows**: Cilium only supports Linux nodes

### Design Considerations

1. **Service endpoints**: Use Kubernetes Services for stable endpoints
2. **External access**: Plan for Ingress controllers or LoadBalancers
3. **Network policies**: Test policies thoroughly before production
4. **Observability**: Use Hubble for network troubleshooting

## Troubleshooting

### Pod Cannot Reach Other Pods

```bash
# Check Cilium agent on node
kubectl logs -n kube-system ds/cilium --tail=50

# Check network policies
kubectl get networkpolicies,ciliumnetworkpolicies --all-namespaces

# Verify CNS health
kubectl get pods -n kube-system -l k8s-app=cilium
```

### Network Policy Not Working

```bash
# Check policy enforcement mode
cilium status | grep "Policy Enforcement"

# View policy decisions in Hubble
cilium hubble observe --verdict DROPPED

# Check policy YAML
kubectl describe ciliumnetworkpolicy <policy-name> -n <namespace>
```

### Performance Issues

```bash
# Check eBPF maps
cilium bpf <map-name> list

# Monitor network metrics
kubectl top pods -n kube-system -l k8s-app=cilium

# View Hubble metrics
kubectl port-forward -n kube-system svc/hubble-metrics 9965:9965
curl http://localhost:9965/metrics
```

## Best Practices

### 1. **Network Policy Design**
- Start with default deny
- Use specific selectors
- Test policies in dev first
- Document policy intent

### 2. **Monitoring**
- Enable Hubble metrics
- Set up alerts for policy denials
- Monitor Cilium agent health
- Track network performance

### 3. **Security**
- Apply least privilege network policies
- Use namespace isolation
- Enable audit logging
- Regular security reviews

### 4. **Performance**
- Monitor eBPF map usage
- Tune Cilium parameters for workload
- Use persistent eBPF maps
- Profile network-intensive apps

## Migration from Other CNIs

If migrating from another CNI plugin to Azure CNS with Cilium:

1. **Backup cluster state**: Snapshots and YAML exports
2. **Create new cluster**: Deploy with Azure CNS configuration
3. **Test workloads**: Verify application compatibility
4. **Migrate network policies**: Convert to Cilium format if needed
5. **Update monitoring**: Configure Hubble and metrics
6. **Cutover**: Move production traffic

**Note**: In-place CNI migration is not supported. Create a new cluster.

## Additional Resources

- [Azure CNI Overlay Documentation](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay)
- [Cilium on AKS](https://learn.microsoft.com/en-us/azure/aks/use-cilium-dataplane)
- [Cilium Network Policies](https://docs.cilium.io/en/stable/security/policy/)
- [Hubble Observability](https://docs.cilium.io/en/stable/gettingstarted/hubble/)
- [Azure AKS Networking Best Practices](https://learn.microsoft.com/en-us/azure/aks/concepts-network)

---

For operational guidance, see [Portal Management Guide](PORTAL-GUIDE.md).
