<div align="center">

# 🌀 fan-control

**Quick notes for reading temperatures and setting the fan PWM on a UniFi gateway.**

![Shell](https://img.shields.io/badge/shell-sh-4EAA25?logo=gnubash&logoColor=white)
![hwmon](https://img.shields.io/badge/Linux-hwmon-blue)

</div>

Two commands, kept in [`sensors_fan_pwm.txt`](sensors_fan_pwm.txt).

## 🚀 Quick start

Run as root over SSH on the device:

```bash
echo 115 > /sys/class/hwmon/hwmon0/pwm1   # set fan PWM (0-255)
sensors                                    # read temperatures and fan speed
```

## 💡 Usage notes

- `115` is roughly 45% duty cycle. Raise it for more cooling, lower it for less noise.
- The `hwmon0` index can differ per model, check `ls /sys/class/hwmon/`.
- The setting does not survive a reboot.

> [!NOTE]
> Known limitation: the change is not persistent and the script does not
> verify that the fan actually responds. Confirm with `sensors`.
