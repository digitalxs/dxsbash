# Security Policy

## Supported Versions

DXSBash updates in place via `update-dxsbash` (or `dxsbash update`), so
security fixes are delivered through the latest release. Only the
current release line receives security updates — if you are on an older
version, please update.

| Version          | Supported          |
| ---------------- | ------------------ |
| 3.5.x (latest)   | :white_check_mark: |
| older releases   | :x: — run `update-dxsbash` |

Check your installed version with:

```bash
dxsbash version        # or: cat ~/linuxtoolbox/dxsbash/version.txt
```

## Reporting a Vulnerability

Send an e-mail to luis@digitalxs.ca

Please include the affected file/script, your dxsbash version, your
distribution and release, and steps to reproduce. You should receive a
response within a few days; please allow time for a fix to be released
before public disclosure.
