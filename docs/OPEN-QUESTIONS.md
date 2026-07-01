# Open questions

## 1. Provisioning mode — ✅ RESOLVED: directory-backed (`dir/v1`) is primary

Directory-backed (**folder-based**) PVCs (`volumeType: dir/v1`) are the target mode.
This is also the stronger least-privilege story: the operator
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
example unless requested.

## 3. Multi-tenancy 2.0

A future Multi-tenancy 2.0 capability may change the org/credential model (e.g.
managed multi-tenant composable clusters via the WEKA Operator). If so, capture the
delta here.

## 4. Exact minimum WEKA role — ✅ RESOLVED: the dedicated `csi` role

WEKA 4.4.10 has a purpose-built **`csi`** role (`weka user add <name> csi <pw>`) —
verified in the lab for both models. It is the least-privilege choice; no need for
OrgAdmin/regular. Model A scopes it to an org; Model B is root-org.
