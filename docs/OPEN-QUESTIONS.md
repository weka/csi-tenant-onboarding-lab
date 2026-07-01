# Open questions — resolve before manifests are authoritative

## 1. Provisioning mode: directory-backed vs filesystem-backed  ⚠️ conflict

- **2026-06-30 Coupang call** referenced the CSI driver's **folder-based (directory)
  PVCs** (`volumeType: dir/v1`) — many PVCs as quota'd directories inside one
  filesystem.
- **Initial lab scoping** picked **filesystem-backed** PVCs (`volumeType: fs`) —
  each PVC is its own WEKA filesystem.

This matters for the credential story (the whole point of the repo):

| | directory-backed (`dir/v1`) | filesystem-backed (`fs`) |
|---|---|---|
| Filesystem lifecycle | pre-created by operator; CSI only makes dirs+quotas | CSI **creates a filesystem per PVC** |
| Minimum WEKA privilege | lower — operate within an existing FS | higher — must be able to **create filesystems** |
| Least-privilege fit | better (no FS-create right needed) | needs OrgAdmin (org) or cluster-level right (root) |

Directory-backed is the *stronger* least-privilege story and is what Coupang is
actually using. **Recommendation: make `dir/v1` the primary example** and keep
`fs` as a documented alternative. Confirm with Rodney.

## 2. Snapshots / data protection

The call raised data protection via **snapshots**. CSI supports snapshot-backed
volumes and clones. Decide whether the lab includes a `VolumeSnapshotClass` +
snapshot/restore demo, and what WEKA privilege snapshotting requires for a
tenant-scoped user.

## 3. Multi-tenancy 2.0

A dedicated MT 2.0 call is planned for the following week. If MT 2.0 changes the
org/credential model, note the delta here and whether this lab should target the
current model, 2.0, or both.

## 4. Exact minimum WEKA role for CSI

Role capability names and the true minimum role for CSI operations are
version-dependent. Verify against the official csi-wekafs docs and the internal
CSI setup pages (Sergey's series) before publishing role recommendations in
`secrets-and-access.md`.
