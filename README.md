# VM Health Check

A lightweight shell script for checking the health of an Ubuntu-based virtual machine (VM) using CPU, memory, and disk usage.

## Overview

This project helps monitor VM health by checking three core system metrics:

- CPU usage
- Memory usage
- Disk usage

The script applies a threshold of 60%:
- If all three metrics are at or below 60%, the VM is reported as Healthy
- If any one of them is above 60%, the VM is reported as Non-Healthy

This is useful for basic monitoring, automation, and alerting in Ubuntu-based virtual environments.

## Why this script exists

Infrastructure and VM health checks often rely on a few key indicators:
- CPU saturation can mean the machine is overloaded
- High memory usage can cause slowdown or failures
- Full disk space can prevent writes, logs, and normal operations

This script gives a simple health assessment based on those indicators.

## Target environment

The script is designed for Ubuntu-based VMs. It uses standard Linux tools commonly available on Ubuntu systems such as:

- top
- free
- df
- awk

## Health logic

The script calculates:

- CPU usage = 100 - idle percentage
- Memory usage = percentage of total memory currently in use
- Disk usage = root filesystem usage (% used on /)

If any of these metrics exceeds 60%, the script marks the VM as:

- Non-Healthy

If all metrics are 60% or below, it marks the VM as:

- Healthy

## Script behavior

The script supports one optional command-line argument:

- no argument: prints overall VM health and a brief summary
- explain: prints detailed metrics and explains why the VM is healthy or non-healthy

## Usage

Make the script executable:

```bash
chmod +x vm_health_check.sh
```

Check health without explanation:

```bash
./vm_health_check.sh
```

Check health with explanation:

```bash
./vm_health_check.sh explain
```

## Example output

### Normal output

```bash
$ ./vm_health_check.sh
Overall: Healthy (CPU: 27.8%, Mem: 42.1%, Disk(/): 51.4%)
```

### Explanation mode

```bash
$ ./vm_health_check.sh explain
VM HEALTH CHECK (threshold: 60%)
---------------------------------------
CPU usage:   27.8 %   => OK
Memory usage: 42.1 %   => OK
Disk (/) used: 51.4 %   => OK

Overall status: Healthy
All checked metrics are below or equal to 60%.
```

### Non-Healthy example

```bash
$ ./vm_health_check.sh explain
VM HEALTH CHECK (threshold: 60%)
---------------------------------------
CPU usage:   78.3 %   => EXCEEDED
Memory usage: 55.2 %   => OK
Disk (/) used: 48.0 %   => OK

Overall status: Non-Healthy
Reasons:
 - CPU usage 78.3% > 60%
```

## Exit codes

The script exits with:
- 0 for Healthy
- 1 for Non-Healthy
- 2 for invalid argument usage

This makes it suitable for use in shell automation and monitoring pipelines.

## File structure

```text
vm-health-check/
├── README.md
├── vm_health_check.sh
└── LICENSE (optional if you add one later)
```

## Script details

### CPU check
The script reads system CPU data from `top` and computes active CPU usage as:

- 100 - idle percentage

### Memory check
The script reads memory values from `free` and calculates:

- percentage used = (total memory - available memory) / total memory * 100

This provides a realistic estimate of actual memory pressure.

### Disk check
The script checks the root filesystem `/` using `df` and reads the used percentage.

## Important notes

- This script checks the root filesystem `/`
- It is intended for Ubuntu VMs
- It is best suited for quick operational monitoring rather than deep performance analysis
- If you need to monitor multiple disks or more advanced metrics, you can extend the script later

## Example use in automation

You can invoke it in a shell script or cron job:

```bash
./vm_health_check.sh explain
```

If the VM is unhealthy, it can be used in an alert pipeline or CI/CD health check.

## Repository purpose

This repository provides a simple and practical VM health check utility for Ubuntu environments. It prioritizes:

- clarity
- simplicity
- portability
- easy integration with scripts and automation tools

## License

This project is distributed under the MIT License unless you choose another license for your repository.

## Summary

This repository contains a simple:
- Ubuntu VM health checker
- CPU, memory, and disk monitoring
- 60% threshold logic
- explain mode for detailed evaluation

It is intentionally minimal and easy to use for system monitoring and alerting.
