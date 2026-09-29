<div align="center">

# 📏 mss-clamp

**A Bash diagnostic that measures the real WAN path MTU and recommends an MSS clamp value.**

![Bash](https://img.shields.io/badge/bash-3.2%2B-4EAA25?logo=gnubash&logoColor=white)
![Linux](https://img.shields.io/badge/platform-Linux%20%7C%20UniFi-0559C9?logo=linux&logoColor=white)
![Version](https://img.shields.io/badge/version-5-blue)

</div>

Built for PPPoE links (MTU 1492, MSS 1452) but works for any WAN type. It
detects the WAN interface, reads the configured clamp from `iptables`, runs a
DF-ping sweep and compares the results.

## ✨ Features

- **WAN auto-detection**: CLI argument, main-table default route, default
  routes in all tables (VPN routes excluded, lowest metric wins), then any UP
  `ppp*` interface.
- **DF-ping sweep**: payloads from 1472 down to 1252 bytes against three public
  anycast targets (`1.1.1.1`, `8.8.8.8`, `9.9.9.9`).
- **Clamp detection**: reads static `TCPMSS set` and clamp-to-PMTU rules.
- **Clear verdict**: reports the binding constraint (interface MTU or path)
  and a `STATUS` line comparing your clamp with the recommendation.
- **UniFi aware**: detects `UBIOS_*_TCPMSS` chains and gives UI guidance,
  including the 1452 cap on the Custom MSS field.
- **Sanitized report**: contains no IPs, MACs or hostnames, safe to share.

## 📦 Prerequisites

| Need | For |
|------|-----|
| Bash, `ip`, `ping` (iputils, supports `-M do`) | Everything |
| `iptables` and root | Reading the configured clamp |

## 🚀 Quick start

```bash
chmod +x MSS_Clamp_diag_v5.sh
./MSS_Clamp_diag_v5.sh          # auto-detect WAN
./MSS_Clamp_diag_v5.sh ppp0     # or force an interface
```

The report is printed and saved to `report.txt` in the current directory.

### Tunables

Edit the variables at the top of the script.

| Variable  | Default | Effect |
|-----------|---------|--------|
| `TARGETS` | `1.1.1.1 8.8.8.8 9.9.9.9` | Hosts to probe |
| `SIZES`   | `1472 … 1252` | Payload sizes to test |
| `COUNT`   | `2` | Pings per test |
| `TIMEOUT` | `3` | Seconds per ping |

## 📁 Output

`report.txt` contains the interface details, the sweep results and a summary
with the empirical path MTU, empirical MSS and a recommendation such as:

- **Native Ethernet (path MTU 1500)**: no clamping needed, set MSS Clamping to
  Auto or Disabled.
- **Reduced MTU (e.g. PPPoE)**: set a custom clamp to the recommended value.

## 💡 Usage notes

- Run it **on the gateway** (SSH), not on a LAN client, to test the WAN path.
- Older versions are kept in [`archive/`](archive/).

> [!NOTE]
> Known limitation: if ICMP is filtered upstream the sweep cannot succeed and
> the script warns instead of recommending a value.

## 🕘 Changelog

| Version | Changes |
|---------|---------|
| 1 | Initial, PPPoE-focused, raw interface dumps |
| 2 | Any WAN type, sanitized output, sizes down to 1252B |
| 3 | Fallback chain for WAN detection |
| 4 | Non-main table detection excludes VPN routes, sorts by metric |
| **5** | Recognizes when clamping is unnecessary (MSS ≥ 1460), UniFi detection and UI guidance, STATUS verdicts moved to the summary |

Full per-version history is kept in the script header.
