# RTK Installation Check

Run when `rtk` misbehaves or after an install.

```bash
rtk --version         # Should show: rtk X.Y.Z
rtk gain              # Should work (not "command not found")
which rtk             # Verify correct binary
```

**Name collision:** if `rtk gain` fails, reachingforthejack/rtk (Rust Type Kit) may be installed instead.
