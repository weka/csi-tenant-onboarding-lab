# Open questions

## 1. Provisioning mode — ✅ RESOLVED: directory-backed (`dir/v1`) is primary

Coupang uses **folder-based (directory) PVCs** (`volumeType: dir/v1`), confirmed on
the 2026-06-30 call. This is also the stronger least-privilege story: the operator
pre-creates the filesystem, so the tenant's CSI user only creates directories +
quotas inside it — no filesystem-create right needed.

- **Primary examples** (`examples/01`, `examples/02`): `dir/v1`.
- **Filesystem-backed (`fs`)** kept as a documented alternative in
  [secrets-and-access.md](secrets-and-access.md#how-provisioning-mode-changes-the-minimum-privilege)
  (needs FS-create privilege → OrgAdmin / cluster-level).

Matches the official [`dynamic_directory`](https://github.com/weka/csi-wekafs/tree/master/examples/dynamic_directory)
example.

## 2. Snapshots / data protection — needs a decision

The call raised data protection via **snapshots**. Important caveat from the
official `dynamic_directory` README:

- A snapshot of a **directory-backed** volume is actually a **whole-filesystem
  snapshot** (all directories on that FS), so it is wasteful and is **disabled by
  default** (`pluginConfig.allowedOperations.snapshotDirectoryVolumes=true`,
  requires a plugin reinstall to enable).
- **Snapshot-backed volumes** (`volumeType: weka/v2`, the
  [`dynamic_snapshot`](https://github.com/weka/csi-wekafs/tree/master/examples/dynamic_snapshot)
  example) are the clean per-volume snapshot/clone path.

Decision needed: does the lab demo snapshots on dir/v1 (with the caveat) or add a
snapshot-backed example? Leaning: mention the caveat in docs, defer a full snapshot
example unless Coupang asks.

## 3. Multi-tenancy 2.0

Dedicated MT 2.0 call planned the following week. Related strategic direction:
Confluence one-pager *"Embedding Kubernetes in WEKA Backends to manage composable
clusters"* explicitly names **Coupang + Core42** wanting managed multi-tenant
composable clusters via the WEKA Operator. If MT 2.0 changes the org/credential
model, capture the delta here.

## 4. Exact minimum WEKA role — verify against installed version

For `dir/v1`, an **OrganizationAdmin** user (Model A) cleanly scopes the tenant. A
**regular** (non-admin) org user may also suffice since it only manipulates
directories/quotas on an existing FS — confirm against the WEKA version on the lab
cluster. CLI syntax (`weka org`, `weka user add --role …`) has evolved across
versions; validate before publishing.
