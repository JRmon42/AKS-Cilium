# Troubleshooting Guide

Common issues and their solutions when working with AKS, Cilium, and related components.

## Table of Contents

- [Deployment Issues](#deployment-issues)
- [Cilium Issues](#cilium-issues)
- [Network Policy Issues](#network-policy-issues)
- [Monitoring Issues](#monitoring-issues)
- [Gatekeeper Issues](#gatekeeper-issues)
- [General Kubernetes Issues](#general-kubernetes-issues)

## Deployment Issues

### Terraform Apply Fails

**Symptom**: Terraform apply fails with authentication errors

**Solution**:
```bash
# Re-login to Azure
az login
az account set --subscription "<subscription-id>"

# Clear Terraform cache
rm -rf .terraform
terraform init
```

---

**Symptom**: Quota exceeded errors

**Solution**:
```bash
# Check quotas
az vm list-usage --location eastus --output table

# Request quota increase via Azure Portal
# Support → New Support Request → Service and Subscription Limits
```

---

**Symptom**: Resource provider not registered

**Solution**:
```bash
# Register required providers
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.Network

# Check registration status
az provider show -n Microsoft.ContainerService --query "registrationState"
```

### AKS Cluster Creation Hangs

**Symptom**: AKS cluster stuck in "Creating" state

**Solution**:
```bash
# Check activity log
az monitor activity-log list --resource-group rg-aks-cilium-demo --max-events 50

# Check for network Issues
az network vnet subnet show --resource-group rg-aks-cilium-demo --vnet-name vnet-aks-cilium-demo --name snet-aks

# If stuck > 30 mins, cancel and retry
terraform destroy -target=azurerm_kubernetes_cluster.aks
terraform apply
```

## Cilium Issues

### Cilium Pods Not Ready

**Symptom**: Cilium pods in CrashLoopBackOff or Not Ready

**Check Status**:
```bash
kubectl get pods -n kube-system -l k8s-app=cilium
kubectl describe pod -n kube-system -l k8s-app=cilium
kubectl logs -n kube-system -l k8s-app=cilium
```

**Common Causes & Solutions**:

1. **Insufficient node resources**
   ```bash
   # Check node resources
   kubectl top nodes
   kubectl describe nodes
   
   # Scale up if needed
   az aks scale --resource-group rg-aks-cilium-demo --name aks-cilium-demo --node-count 4
   ```

2. **Network configuration issues**
   ```bash
   # Verify network profile
   az aks show --resource-group rg-aks-cilium-demo --name aks-cilium-demo --query networkProfile
   
   # Should show:
   # networkDataplane: cilium
   # networkPlugin: none
   # networkPolicy: cilium
   ```

3. **Kernel version incompatibility**
   ```bash
   # Check kernel version on nodes
   kubectl debug node/<node-name> -it --image=ubuntu -- uname -r
   
   # Cilium requires kernel >= 4.9
   ```

### Cilium Status Check Fails

**Symptom**: `cilium status` returns errors

**Solution**:
```bash
# Port forward to Cilium agent
kubectl port-forward -n kube-system ds/cilium 9962:9962

# Check connectivity
curl http://localhost:9962/healthz

# Reinstall Cilium CLI if needed
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
```

### Hubble UI Not Accessible

**Symptom**: Cannot access Hubble UI

**Solution**:
```bash
# Check if Hubble is enabled
cilium hubble enable --ui

# Check Hubble pods
kubectl get pods -n kube-system -l k8s-app=hubble

# Port forward manually
kubectl port-forward -n kube-system svc/hubble-ui 12000:80

# Check Hubble relay
kubectl logs -n kube-system -l k8s-app=hubble-relay
```

## Network Policy Issues

### Network Policies Not Enforced

**Symptom**: Traffic not being blocked by policies

**Diagnosis**:
```bash
# Check if Cilium is enforcing policies
kubectl exec -n kube-system ds/cilium -- cilium status | grep "Policy enforcement"

# Check policy mode
kubectl exec -n kube-system ds/cilium -- cilium config | grep policy-enforcement

# List all network policies
kubectl get cnp --all-namespaces
```

**Solution**:
```bash
# Verify policy syntax
kubectl get cnp <policy-name> -n <namespace> -o yaml

# Check Cilium endpoints
kubectl exec -n kube-system ds/cilium -- cilium endpoint list

# View policy verdict
cilium hubble observe --verdict DROPPED --namespace demo-app
```

### DNS Resolution Failing

**Symptom**: Pods cannot resolve DNS names

**Check**:
```bash
# Test DNS from pod
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check DNS policy
kubectl get cnp -n demo-app | grep dns
```

**Solution**:
```bash
# Ensure DNS policy is applied
kubectl apply -f manifests/network-policies/04-allow-dns.yaml

# Restart CoreDNS if needed
kubectl rollout restart deployment coredns -n kube-system
```

### Layer 7 Policies Not Working

**Symptom**: L7 HTTP policies not filtering traffic

**Diagnosis**:
```bash
# Check if L7 proxy is enabled
kubectl exec -n kube-system ds/cilium -- cilium status | grep "L7 Proxy"

# View L7 policy logs
kubectl exec -n kube-system ds/cilium -- cilium monitor -t l7
```

**Solution**:
```bash
# Ensure policy has correct L7 rules
kubectl get cnp <policy-name> -o yaml | grep -A 10 "http:"

# Check endpoint policy status
kubectl exec -n kube-system ds/cilium -- cilium endpoint list -o json | jq '.[] | select(.status.policy.realized.l7-proxy != null)'
```

## Monitoring Issues

### Prometheus Not Scraping Metrics

**Symptom**: Metrics not appearing in Prometheus

**Check Targets**:
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090/targets
```

**Common Issues**:

1. **ServiceMonitor not found**
   ```bash
   kubectl get servicemonitor -n kube-system
   kubectl get servicemonitor -n monitoring
   ```

2. **Metrics endpoint not accessible**
   ```bash
   # Test endpoint directly
   kubectl exec -n kube-system <cilium-pod> -- curl localhost:9962/metrics
   ```

3. **RBAC permissions**
   ```bash
   kubectl get clusterrolebinding | grep prometheus
   kubectl describe clusterrole prometheus-kube-prometheus-prometheus
   ```

### Grafana Dashboards Empty

**Symptom**: Grafana shows no data

**Solution**:
```bash
# Check Prometheus data source
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Login and check Configuration → Data Sources

# Verify Prometheus is running
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus

# Check Prometheus has data
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Query: up{job="cilium-agent"}
```

### Alert Manager Not Sending Alerts

**Symptom**: Alerts firing but no notifications

**Check Configuration**:
```bash
# View AlertManager config
kubectl get secret -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d

# Check AlertManager status
kubectl logs -n monitoring -l app.kubernetes.io/name=alertmanager
```

## Gatekeeper Issues

### Constraints Not Enforcing

**Symptom**: Non-compliant resources being created

**Diagnosis**:
```bash
# Check Gatekeeper status
kubectl get pods -n gatekeeper-system

# Check constraint status
kubectl get constraints

# View specific constraint
kubectl get k8srequiredlabels require-common-labels -o yaml
```

**Common Causes**:

1. **Enforcement action set to dryrun**
   ```bash
   # Check enforcement action
   kubectl get k8srequiredlabels -o jsonpath='{.items[*].spec.enforcementAction}'
   
   # Change to deny
   kubectl patch k8srequiredlabels require-common-labels --type='json' -p='[{"op": "replace", "path": "/spec/enforcementAction", "value": "deny"}]'
   ```

2. **Namespace excluded**
   ```bash
   # Check excluded namespaces
   kubectl get k8srequiredlabels require-common-labels -o jsonpath='{.spec.match.excludedNamespaces}'
   ```

3. **Gatekeeper webhook not registered**
   ```bash
   kubectl get validatingwebhookconfigurations | grep gatekeeper
   ```

### Template Errors

**Symptom**: ConstraintTemplate showing errors

**Check**:
```bash
# View template status
kubectl get constrainttemplate <template-name> -o yaml

# Check for Rego errors
kubectl logs -n gatekeeper-system -l control-plane=controller-manager | grep -i error
```

**Solution**:
```bash
# Test Rego policy at play.openpolicyagent.org

# Delete and recreate template
kubectl delete constrainttemplate <template-name>
kubectl apply -f manifests/constraints/templates/<template-file>.yaml
```

### Audit Violations Not Showing

**Symptom**: Violations not appearing in constraint status

**Solution**:
```bash
# Check audit controller
kubectl logs -n gatekeeper-system -l control-plane=audit-controller

# Trigger manual audit
kubectl delete pod -n gatekeeper-system -l control-plane=audit-controller

# Check audit interval
kubectl get deployment -n gatekeeper-system gatekeeper-audit -o yaml | grep auditInterval
```

## General Kubernetes Issues

### Pods Stuck in Pending

**Diagnosis**:
```bash
# Describe the pod
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl top nodes
kubectl describe nodes
```

**Common Causes**:

1. **Insufficient resources**
   ```bash
   # Scale cluster
   az aks scale --resource-group rg-aks-cilium-demo --name aks-cilium-demo --node-count 4
   ```

2. **PVC not bound**
   ```bash
   kubectl get pvc -n <namespace>
   kubectl describe pvc <pvc-name> -n <namespace>
   ```

3. **Image pull error**
   ```bash
   kubectl describe pod <pod-name> -n <namespace> | grep -A 5 "Events:"
   ```

### Unable to Connect to Cluster

**Symptom**: kubectl commands fail with connection errors

**Solution**:
```bash
# Get fresh credentials
az aks get-credentials --resource-group rg-aks-cilium-demo --name aks-cilium-demo --overwrite-existing

# Check cluster status
az aks show --resource-group rg-aks-cilium-demo --name aks-cilium-demo --query provisioningState

# Test connection
kubectl cluster-info

# Check kubectl context
kubectl config current-context
```

### Node NotReady

**Symptom**: Nodes showing NotReady status

**Check**:
```bash
# View node status
kubectl get nodes
kubectl describe node <node-name>

# Check node conditions
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
```

**Solution**:
```bash
# Restart node (Azure will replace it)
az vmss deallocate --resource-group <MC_resource_group> --name <vmss-name> --instance-ids <instance-id>
az vmss start --resource-group <MC_resource_group> --name <vmss-name> --instance-ids <instance-id>

# Or let AKS auto-repair handle it (wait 10-15 minutes)
```

## Getting Help

If issues persist:

1. **Collect diagnostics**:
   ```bash
   # AKS diagnostics
   az aks kanalyze --resource-group rg-aks-cilium-demo --name aks-cilium-demo
   
   # Cilium diagnostics
   cilium sysdump
   
   # kubectl diagnostics
   kubectl cluster-info dump --output-directory=./cluster-dump
   ```

2. **Check logs**:
   ```bash
   # All pods in kube-system
   kubectl logs -n kube-system --all-containers=true --prefix=true -l k8s-app=cilium
   
   # Gatekeeper logs
   kubectl logs -n gatekeeper-system --all-containers=true
   
   # Monitoring logs
   kubectl logs -n monitoring --all-containers=true -l app.kubernetes.io/name=prometheus
   ```

3. **Resources**:
   - [AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
   - [Cilium Documentation](https://docs.cilium.io/)
   - [OPA Gatekeeper Documentation](https://open-policy-agent.github.io/gatekeeper/)
   - [Prometheus Documentation](https://prometheus.io/docs/)

4. **Community Support**:
   - AKS: GitHub Issues, Microsoft Q&A
   - Cilium: Slack (#general channel)
   - Gatekeeper: GitHub Issues
