# Multi-tenancy design guide (WEKA + CSI) — decision layer

> **Status: SKELETON / DRAFT.** This is the *judgment layer* that sits above
> [`csi-guidance.md`](csi-guidance.md) and [`csi-howto.md`](csi-howto.md): not "which
> knobs exist" but "which knob to turn, and where you'll top out." Sections below are
> outlined; `TODO` marks content to fill and, especially, **numbers to verify against
> the running WEKA version before publishing.**
>
> Scope note: everything here describes the **WEKA 4.4.x** tenancy model. WEKA 5.x is
> expected to reshape it (see [§7](#7-near-future-tenant-20-in-weka-5x)). Keep the 4.x
> content fenced so it doesn't silently rot the day 5.x ships.

The pieces below are each easy in isolation. What's rare — and what this guide is for —
is holding all of them at once and knowing how they compose into "safely hand a tenant
a slice of the cluster."

---

## 1. Least-privilege credentials — the `csi` role

- The default install drops **cluster-admin** creds into a k8s Secret → wrong blast radius.
- WEKA ships a dedicated **`csi` role** = exactly the provisioner's operations, nothing more.
- This is table stakes for everything below; covered in [`secrets-and-access.md`](secrets-and-access.md).
- TODO: cross-link, keep this section a pointer not a duplicate.

## 2. WEKA Organizations — what they are and when to reach for one

- The rarely-used primitive: most clusters never leave the **root org**, so "orgs exist"
  is already niche knowledge.
- Org = control-plane + data-plane **tenant boundary**: a tenant's users/filesystems are
  invisible outside the org (a filesystem in a tenant org isn't even visible to a root-org
  admin listing).
- The judgment: reach for a dedicated org when you need a **hard** tenant boundary; skip it
  when a StorageClass pin + quota is enough.
- TODO: short "when do I actually need an org?" decision paragraph.

## 3. The two isolation models — trust boundaries, side by side

Both already implemented in `examples/01-org-tenant/` and `examples/02-root-org-tenant/`.
This section is the *why*, framed as trust boundary vs operational cost.

| | Model A — dedicated Org | Model B — root org + dedicated FS |
|---|---|---|
| Boundary | native WEKA org isolation (strong) | StorageClass `filesystemName` + quota (weaker) |
| Cost | more orgs to manage | simpler, but no org fence |
| Use when | strict / low-trust tenant | lighter-weight, higher-trust tenant |

- The real question isn't "A or B" — it's **"how much do I trust this tenant, and what
  operational overhead am I willing to pay for isolation?"**
- TODO: map each model to a trust posture + who administers what.

## 4. Directory- vs filesystem-backed PVCs (`dir/v1` vs filesystem)

The quiet decision with loud consequences — the CSI config accepts either without complaint.

- **Directory-backed (`dir/v1`):** many PVCs share one filesystem. Lightweight, fast to
  provision — but they **share** that filesystem's quota / snapshot / performance boundary.
- **Filesystem-backed:** each PVC is a real WEKA filesystem. Hard isolation, independent
  snapshots and quota — but **spends filesystem count** (see [§5](#5-filesystem-limits--the-scaling-ceiling)).
- In a multi-tenant context this is part of the *same* isolation story as §2–3, not a footnote.
- TODO: decision table (isolation need → provisioning mode), and note current example uses `dir/v1`.
- TODO: confirm exact `volumeType` strings + capabilities for the FS-backed / `weka/v2`
  (snapshot-backed) path against the target CSI version.

## 5. Filesystem limits — the scaling ceiling

This is where "just give every tenant its own filesystem" quietly sets a **hard tenant cap**.
Works great at 10 tenants in the POC; falls off a cliff at the limit, and nobody sees it
coming because the CSI config never complains until the wall.

- There is a **per-org** filesystem limit and a **cluster-wide** filesystem limit.
- ⚠️ **TODO — VERIFY, do not quote from memory:** exact per-org limit and cluster-wide
  limit for the running WEKA version (they are version-dependent; pin the number to a
  release before this goes into official docs).
- Consequence: filesystem-per-tenant isolation (§4) has a finite headroom → capacity-plan
  the tenant count against the limit up front.

## 6. Quotas & snapshots — how they interact with isolation granularity

Not separate topics — they're the levers that decide whether you *have to* spend a
filesystem per tenant.

- **Quotas** = the escape valve: get *some* isolation (capacity fairness) **within** a
  shared filesystem, so you stay under the §5 limit without a filesystem per tenant.
- **Snapshots** are **per-filesystem** → your isolation granularity *is* your backup/restore
  granularity. Directory-backed tenants sharing a filesystem **cannot** be snapshotted or
  rolled back independently.
- Therefore: a tenant that needs its own restore timeline can *force* filesystem-per-tenant —
  pushing you back toward the §5 ceiling. That trade is the crux of the whole guide.
- TODO: worked example — N tenants, snapshot requirement → filesystem budget math.

## 7. Near-future: Tenant 2.0 in WEKA 5.x

- WEKA 5.x is expected to rework the tenancy primitive and may **collapse much of the
  org-per-tenant gymnastics** this guide documents for 4.x.
- ⚠️ **TODO — roadmap, unverified:** capture the actual 5.x model, any changed
  per-org / cluster filesystem limits, and how quotas/snapshots behave under it. Do **not**
  guess specifics here; fill in from official 5.x material when available.
- Why write the 4.x guide now anyway: customers need it **today** on 4.4.x. Keep the 4.x/5.x
  boundary explicit so this doc degrades gracefully rather than misleading after 5.x ships.

---

## Open items feeding this guide

- [ ] §5: confirm per-org and cluster-wide filesystem limits for the target version.
- [ ] §4: confirm FS-backed / `weka/v2` snapshot-backed provisioning `volumeType` + behavior.
- [ ] §7: Tenant 2.0 / 5.x model + limits (blocked on 5.x material).
- [ ] Reconcile with README "Possible extensions" (Multi-tenancy 2.0 alignment, `weka/v2` example).
