<div align="center">

# 📡 ubiquity

**A toolbox of Graylog parsers and network diagnostics for UniFi / Ubiquiti gear.**

![Bash](https://img.shields.io/badge/bash-scripts-4EAA25?logo=gnubash&logoColor=white)
![Graylog](https://img.shields.io/badge/Graylog-5.x-FF3633?logo=graylog&logoColor=white)
![UniFi](https://img.shields.io/badge/UniFi-gateway%20%7C%20AP%20%7C%20switch-0559C9?logo=ubiquiti&logoColor=white)

</div>

Small, self-contained pieces I use to run and troubleshoot a UniFi network.
Each folder has its own README.

## ✨ Contents

| Folder | What it is |
|--------|------------|
| [`graylog/`](graylog/) | Importable Graylog extractors and grok patterns for UniFi gateway, AP and switch syslog |
| [`mss-clamp/`](mss-clamp/) | Diagnostic script that finds the real WAN path MTU and recommends an MSS clamp value (PPPoE and others) |
| [`fan-control/`](fan-control/) | Notes for reading sensors and setting the fan PWM on a UniFi gateway |

## 🚀 Quick start

```bash
git clone https://github.com/usrnmhcs5he/ubiquity
cd ubiquity
```

- **Graylog**: see [`graylog/README.md`](graylog/README.md) for import steps.
- **MSS diagnostic**: copy the script to the gateway and run it there, see
  [`mss-clamp/README.md`](mss-clamp/README.md).

## 📁 Layout

```
ubiquity/
├── graylog/
│   ├── extractors/   importable JSON extractors
│   └── grok/         raw grok patterns
├── mss-clamp/
│   ├── MSS_Clamp_diag_v5.sh
│   └── archive/      older versions
└── fan-control/
    └── sensors_fan_pwm.txt
```

> [!NOTE]
> The MSS script and grok patterns are written for UniFi output but rely only
> on standard Linux tooling and syslog formats.
