# Architecture & trust boundary

_TODO — diagram + narrative._

Key elements to cover:

- **WEKA cluster** (operator-owned): backends, management endpoints, Organizations,
  filesystems, capacity quotas.
- **Tenant baremetal host**: runs a single-node Kubernetes cluster; joins WEKA as a
  **stateless, CSI-managed client** (no manual `weka agent install`).
- **Trust boundary**: sits at the WEKA API user in the CSI Secret. The tenant is
  handed a scoped user; the operator retains admin. Everything the tenant's CSI
  can do on WEKA is bounded by that user's org + role + quota.
- **Network**: management reachability (`endpoints`) + data path from host to WEKA.

See [secrets-and-access.md](secrets-and-access.md) for the credential detail.
