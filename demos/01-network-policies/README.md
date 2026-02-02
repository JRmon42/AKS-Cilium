# Network Policies Demo

Demo script for Cilium Network Policies on AKS.

## What This Demo Shows

1. Deploying a 3-tier application (frontend, backend, database)
2. Testing connectivity without policies
3. Applying default deny policies
4. Selectively allowing traffic between tiers
5. Layer 7 HTTP policies
6. FQDN-based egress policies
7. Visualizing network flows with Hubble

## Prerequisites

- AKS cluster with Cilium deployed
- kubectl configured
- Cilium CLI installed

## Running the Demo

### Option 1: Automated Script

```bash
chmod +x run-demo.sh
./run-demo.sh
```

### Option 2: Manual Steps

Follow the instructions in `../../manifests/network-policies/README.md`

## Expected Outcomes

- ✓ Frontend can access Backend
- ✓ Backend can access Database
- ✗ Frontend cannot access Database (blocked by policy)
- ✓ L7 policies filter HTTP methods
- ✓ FQDN policies control external access

## Visualization

After running the demo, visualize the network flows:

```bash
# Start Hubble UI
cilium hubble ui

# Generate traffic
kubectl exec -it -n demo-app deployment/frontend -- sh -c 'while true; do wget -O- http://backend:5678; sleep 2; done'

# Watch flows
cilium hubble observe --namespace demo-app --follow
```

## Cleanup

```bash
kubectl delete namespace demo-app
```
