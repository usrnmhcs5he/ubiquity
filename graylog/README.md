<div align="center">

# 🪵 graylog

**Importable extractors and grok patterns that turn raw UniFi syslog into searchable fields.**

![Graylog](https://img.shields.io/badge/Graylog-5.0.x-FF3633?logo=graylog&logoColor=white)
![Grok](https://img.shields.io/badge/pattern-grok-blue)
![Input](https://img.shields.io/badge/input-Syslog%20UDP-lightgrey)

</div>

Devices send syslog over UDP to a Graylog input. These extractors parse the
`message` field so you can search and build dashboards on firewall, WiFi,
DHCP, PoE and temperature data. Only **new** messages are parsed, old ones stay
as they are.

## ✨ Features

- **Combined AP + firewall extractor**: one extractor covering firewall
  (`IN=`/`OUT=`/`SRC=`/`DST=`), `hostapd` client events, `dhcpd` leases and AP
  temperature/fan lines.
- **Switch extractor**: PoE state per port, port up/down, watchdog, firmware
  and restart events. Applies only to messages matching `U?SW|Switch|USW`.
- **Gateway firewall grok**: parses custom-rule log lines with `DESCR=`,
  `MAC=`, `SPT=` and `DPT=` from a UniFi gateway.
- **AP temperature grok**: named captures only, extracts `wifi_interface` and
  `wifi_temp`.

## 📦 Prerequisites

| Need | For |
|------|-----|
| Graylog 5.0.x or newer | Extractor JSON import (files are exported as version `5.0.7`) |
| A Syslog UDP input receiving UniFi logs | Everything |

## 🚀 Quick start

**JSON extractors** (`extractors/`):

1. *System → Inputs*, find your Syslog UDP input, click *Manage extractors*.
2. *Actions → Import extractors*, paste the file contents, *Add extractors to input*.

**Grok patterns** (`grok/`): in the same screen choose *Get started → Load
message → Select extractor type → Grok pattern*, paste the pattern, set the
source field to `message`. Or use them as the `grok_pattern` of a pipeline rule.

## 📁 Files

| File | Type | Extracts |
|------|------|----------|
| `extractors/unifi-ap-firewall-combined.json` | Extractor | `priority`, `timestamp`, `device_model`, `device_id`, `firmware_version`, `process`, firewall fields, `client_mac`, `event`, `client_ip`, `wifi_temp`, `fan_speed` |
| `extractors/unifi-switch-operational-logs.json` | Extractor | `device_model`, `process`, `poe_status`, `poe_port`, `port_number`, `port_event`, `watchdog_event`, `firmware_version` |
| `grok/unifi-gateway-firewall.grok` | Grok | `rule_prefix`, `description`, `in_interface`, `out_interface`, `mac_address`, `src_ip`, `dst_ip`, `protocol`, `src_port`, `dst_port` and more |
| `grok/unifi-ap-temperature.grok` | Grok | `wifi_interface`, `wifi_temp` |

## 💡 Usage notes

- Extractor `order` is 0 for the combined one and 2 for the switch one, so
  the combined extractor runs first. Adjust if fields overlap.
- Example searches: `wifi_temp:>75`, `poe_status:* AND poe_port:12`,
  `dst_port:22 AND protocol:TCP`.

> [!NOTE]
> Known limitation: the `.grok` files include comment lines at the top. Strip
> the leading `#` lines and paste only the pattern line.

## 🕘 Changelog

| Version | Changes |
|---------|---------|
| 1 | Initial extractors and grok patterns, reorganized into `extractors/` and `grok/` |
