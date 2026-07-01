# References

## Official csi-wekafs examples (GitHub — the manifests here are derived from these)

- [examples/](https://github.com/weka/csi-wekafs/tree/master/examples) — index
- [common/csi-wekafs-api-secret.yaml](https://github.com/weka/csi-wekafs/blob/master/examples/common/csi-wekafs-api-secret.yaml)
  — canonical Secret template (all keys + comments)
- [dynamic_directory/](https://github.com/weka/csi-wekafs/tree/master/examples/dynamic_directory)
  — **directory-backed (`dir/v1`)**, i.e. Coupang's mode. StorageClass, PVC, app,
  snapshot/clone.
- [dynamic_filesystem/](https://github.com/weka/csi-wekafs/tree/master/examples/dynamic_filesystem)
  — filesystem-backed (`fs`) alternative
- [dynamic_snapshot/](https://github.com/weka/csi-wekafs/tree/master/examples/dynamic_snapshot)
  — snapshot-backed volumes (`weka/v2`), the clean per-volume snapshot/clone path

> The official examples ship with `admin/admin` in the Secret and do **not** cover
> tenant-scoped credentials — which is exactly the gap this lab fills.

## Sergey's CSI design series (Confluence — wekaio.atlassian.net)

Author: **Sergey Berezansky** (WEKA CSI plugin designer/owner). Design-era docs,
useful for intent/behavior, not user-facing config:

- [Weka K8s CSI Plugin](https://wekaio.atlassian.net/wiki/spaces/GUID/pages/785711111) — design overview
- [CSI Plugin v1 (With FS and quota support)](https://wekaio.atlassian.net/wiki/spaces/GUID/pages/1503330389) — dir-quota / filesystem / snapshot support; owner Sergey Berezansky
- [CSI Plugin for WekaFS](https://wekaio.atlassian.net/wiki/spaces/SR/pages/733348827) — Identity Service APIs / capabilities
- [CSI Plugin for WekaFS - Phase #1](https://wekaio.atlassian.net/wiki/spaces/SR/pages/846987283)
- [CSI Plugin outline](https://wekaio.atlassian.net/wiki/spaces/~62440860ed4d6b007012a45e/pages/2005008385)

## WEKA multi-tenancy / roles (Confluence)

- [Multiple Organizations in one weka cluster](https://wekaio.atlassian.net/wiki/spaces/SR/pages/683311158)
  — the ClusterAdmin / OrganizationAdmin / regular / readonly role model; org
  isolation guarantees. Source for the role facts in
  [secrets-and-access.md](secrets-and-access.md).

## Strategic context (Coupang)

- [One Pager — Embedding Kubernetes in WEKA Backends to manage composable clusters](https://wekaio.atlassian.net/wiki/spaces/~5bfd09146b98a11ccd361ec7/pages/2927624215)
  — names **Coupang + Core42** wanting managed, isolated multi-tenant composable
  clusters via the WEKA Operator. Longer-term direction behind this ask; ties to
  Multi-tenancy 2.0 (OPEN-QUESTIONS #3).
