# References

## Official csi-wekafs examples (the manifests here are derived from these)

- [examples/](https://github.com/weka/csi-wekafs/tree/master/examples) — index
- [common/csi-wekafs-api-secret.yaml](https://github.com/weka/csi-wekafs/blob/master/examples/common/csi-wekafs-api-secret.yaml)
  — canonical Secret template (all keys + comments)
- [dynamic_directory/](https://github.com/weka/csi-wekafs/tree/master/examples/dynamic_directory)
  — **directory-backed (`dir/v1`)** volumes: StorageClass, PVC, app, snapshot/clone
- [dynamic_filesystem/](https://github.com/weka/csi-wekafs/tree/master/examples/dynamic_filesystem)
  — filesystem-backed (`fs`) alternative
- [dynamic_snapshot/](https://github.com/weka/csi-wekafs/tree/master/examples/dynamic_snapshot)
  — snapshot-backed volumes (`weka/v2`), the clean per-volume snapshot/clone path

> The official examples ship with `admin/admin` in the Secret and do **not** cover
> tenant-scoped credentials — which is exactly the gap this repo fills.

## WEKA docs

- WEKA CSI Plugin documentation: <https://docs.weka.io> (CSI Plugin section)
- WEKA multi-tenancy / Organizations and the role model (incl. the `csi` role):
  see the WEKA administration documentation.
