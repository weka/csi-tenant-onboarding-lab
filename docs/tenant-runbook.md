# Tenant runbook — consuming WEKA storage from your k8s cluster

_TODO — fill with validated steps once provisioning mode is confirmed and the lab
has been run end-to-end._

Outline:

1. Stand up single-node Kubernetes on the baremetal host (k3s / kubeadm).
2. Ensure network reachability to the WEKA management `endpoints` and data path.
3. Create the CSI Secret from the credentials the operator provided
   (see `examples/*/`). Keep it in a namespace only the platform team can read.
4. `helm install` the [csi-wekafs](https://github.com/weka/csi-wekafs) plugin with
   values for a **stateless, CSI-managed client**.
5. Apply the StorageClass (points at the Secret + filesystem).
6. Create a PVC + a pod that writes to it — confirm read/write.
7. (Optional) snapshot / restore demo.
