# Network Policies Demo

This directory contains Cilium Network Policy examples demonstrating various network security scenarios.

## Files Overview

- **00-namespace.yaml**: Creates the demo namespace
- **01-sample-apps.yaml**: Deploys a 3-tier application (frontend, backend, database)
- **02-default-deny.yaml**: Default deny all traffic policy
- **03-allow-specific-traffic.yaml**: Allow specific pod-to-pod communication
- **04-allow-dns.yaml**: Allow DNS resolution
- **05-l7-policy.yaml**: Layer 7 HTTP policy
- **06-fqdn-policy.yaml**: FQDN-based egress policy

## Quick Start

### 1. Deploy Sample Applications

```bash
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-sample-apps.yaml
```

### 2. Test Connectivity Before Policies

```bash
# Get a shell in frontend pod
kubectl exec -it -n demo-app deployment/frontend -- sh

# Test connectivity to backend (should work)
wget -O- http://backend:5678

# Test connectivity to database (should work)
nc -zv database 5432
```

### 3. Apply Network Policies

```bash
# Apply default deny (blocks all traffic)
kubectl apply -f 02-default-deny.yaml

# Test again - should fail now
kubectl exec -it -n demo-app deployment/frontend -- wget -O- --timeout=2 http://backend:5678

# Allow specific traffic
kubectl apply -f 03-allow-specific-traffic.yaml
kubectl apply -f 04-allow-dns.yaml

# Test again - should work now
kubectl exec -it -n demo-app deployment/frontend -- wget -O- http://backend:5678
```

### 4. Test Layer 7 Policies

```bash
# Apply L7 HTTP policy
kubectl apply -f 05-l7-policy.yaml

# Only GET requests should work
kubectl exec -it -n demo-app deployment/frontend -- wget -O- http://backend:5678
```

### 5. Test FQDN Policies

```bash
# Apply FQDN policy
kubectl apply -f 06-fqdn-policy.yaml

# Test allowed domain (should work)
kubectl exec -it -n demo-app deployment/backend -- wget -O- --timeout=5 https://api.github.com

# Test blocked domain (should fail)
kubectl exec -it -n demo-app deployment/backend -- wget -O- --timeout=5 https://www.example.com
```

## Visualize with Hubble

```bash
# Enable Hubble UI
cilium hubble ui

# In another terminal, generate traffic
kubectl exec -it -n demo-app deployment/frontend -- sh -c 'while true; do wget -O- http://backend:5678; sleep 2; done'

# Watch flows in real-time
cilium hubble observe --namespace demo-app --follow
```

## Cleanup

```bash
kubectl delete namespace demo-app
```

## Policy Explanation

### Default Deny Policy
Blocks all ingress and egress traffic by default. This is a security best practice.

### Selective Allow Policies
- Frontend can talk to Backend on port 5678
- Backend can talk to Database on port 5432
- All pods can perform DNS queries

### Layer 7 Policy
- Inspects HTTP traffic
- Only allows GET requests
- Can filter by path, headers, etc.

### FQDN Policy
- Controls egress to external services
- Based on DNS names
- Useful for SaaS integrations

## Best Practices

1. **Start with Default Deny**: Always begin with a default deny policy
2. **Be Specific**: Define precise selectors and ports
3. **Test Incrementally**: Add policies one at a time
4. **Monitor with Hubble**: Visualize traffic flows
5. **Document Policies**: Clearly describe the intent
6. **Use Layer 7 for HTTP/gRPC**: Leverage Cilium's L7 capabilities
7. **Group Related Policies**: Keep policies organized by application
