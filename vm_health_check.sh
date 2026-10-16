#!/usr/bin/env bash
#
# vm_health_check.sh
#
# Check VM health based on CPU, Memory and Disk usage on Ubuntu.
# - Threshold: 60%
# - If ANY metric is > 60% the VM is considered "Non-Healthy"
# - Otherwise the VM is "Healthy"
#
# Usage:
#   ./vm_health_check.sh            # prints overall health + brief metrics
#   ./vm_health_check.sh explain    # prints overall health + detailed reasons
#
# Notes:
# - CPU usage is computed as (100 - %idle) from `top`.
# - Memory usage uses "available" from `free` to compute real used percent.
# - Disk usage checks root filesystem (/) percent used from `df`.
# - Written to be compatible with standard Ubuntu installs.

THRESHOLD=60

print_usage() {
  cat <<EOF
Usage: $0 [explain]

If "explain" is provided, the script prints detailed reasons (metric values and
which metrics exceeded the threshold). Otherwise it prints the overall health
and brief metric values.
EOF
}

# Parse arg
EXPLAIN=false
if [ "$#" -gt 1 ]; then
  print_usage
  exit 2
fi
if [ "$#" -eq 1 ]; then
  if [ "$1" = "explain" ]; then
    EXPLAIN=true
  else
    print_usage
    exit 2
  fi
fi

# Get CPU usage (percentage used = 100 - idle)
# Use top to get the "id" (idle) value and compute used
cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed -n 's/.*, *\([0-9.]*\) id.*/\1/p')
if [ -z "$cpu_idle" ]; then
  # fallback using /proc/stat sampling (works even if top format differs)
  read -r cpu a b c d e f g < /proc/stat
  total1=$((a+b+c+d+e+f+g))
  idle1=$d
  sleep 0.2
  read -r cpu a b c d e f g < /proc/stat
  total2=$((a+b+c+d+e+f+g))
  idle2=$d
  total_diff=$((total2 - total1))
  idle_diff=$((idle2 - idle1))
  if [ "$total_diff" -gt 0 ]; then
    cpu_usage=$(awk -v t="$total_diff" -v i="$idle_diff" 'BEGIN{printf "%.1f", (1 - i/t) * 100}')
  else
    cpu_usage="0.0"
  fi
else
  cpu_usage=$(awk -v idle="$cpu_idle" 'BEGIN{printf "%.1f", 100 - idle}')
fi

# Get memory usage using `free` (use available if present)
# mem_used_percent = (total - available) / total * 100
if free --help >/dev/null 2>&1; then
  read -r mem_total mem_avail < <(free -m | awk '/^Mem:/ {print $2, ($7 == "" ? $3 : $7)}')
  if [ -z "$mem_total" ] || [ -z "$mem_avail" ]; then
    mem_total=$(free -m | awk '/^Mem:/ {print $2}')
    mem_used=$(free -m | awk '/^Mem:/ {print $3}')
    mem_avail=$((mem_total - mem_used))
  fi
  mem_used_percent=$(awk -v t="$mem_total" -v a="$mem_avail" 'BEGIN{if(t>0) printf "%.1f", (1 - a/t) * 100; else print "0.0"}')
else
  mem_used_percent="0.0"
fi

# Get disk usage for root filesystem
# Use POSIX df (-P) and parse percent used for /
disk_used_percent=$(df -P / | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
if [ -z "$disk_used_percent" ]; then
  disk_used_percent="0"
fi
disk_used_percent=$(awk -v v="$disk_used_percent" 'BEGIN{printf "%.1f", v}')

# Determine health: if ANY metric > THRESHOLD -> Non-Healthy
is_non_healthy=false
cpu_status="OK"
mem_status="OK"
disk_status="OK"
reason_list=()

if awk -v val="$cpu_usage" -v t="$THRESHOLD" 'BEGIN{exit !(val > t)}'; then
  is_non_healthy=true
  cpu_status="EXCEEDED"
  reason_list+=("CPU usage ${cpu_usage}% > ${THRESHOLD}%")
fi

if awk -v val="$mem_used_percent" -v t="$THRESHOLD" 'BEGIN{exit !(val > t)}'; then
  is_non_healthy=true
  mem_status="EXCEEDED"
  reason_list+=("Memory usage ${mem_used_percent}% > ${THRESHOLD}%")
fi

if awk -v val="$disk_used_percent" -v t="$THRESHOLD" 'BEGIN{exit !(val > t)}'; then
  is_non_healthy=true
  disk_status="EXCEEDED"
  reason_list+=("Disk (/) usage ${disk_used_percent}% > ${THRESHOLD}%")
fi

overall_health="Healthy"
if [ "$is_non_healthy" = true ]; then
  overall_health="Non-Healthy"
fi

# Output
if [ "$EXPLAIN" = true ]; then
  echo "VM HEALTH CHECK (threshold: ${THRESHOLD}%)"
  echo "---------------------------------------"
  printf "CPU usage:    %6s %%   => %s\n" "$cpu_usage" "$cpu_status"
  printf "Memory usage: %6s %%   => %s\n" "$mem_used_percent" "$mem_status"
  printf "Disk (/) used:%6s %%   => %s\n" "$disk_used_percent" "$disk_status"
  echo
  if [ "$is_non_healthy" = true ]; then
    echo "Overall status: $overall_health"
    echo "Reasons:"
    for r in "${reason_list[@]}"; do
      echo " - $r"
    done
    exit 1
  else
    echo "Overall status: $overall_health"
    echo "All checked metrics are below or equal to ${THRESHOLD}%."
    exit 0
  fi
else
  printf "Overall: %s (CPU: %s%%, Mem: %s%%, Disk(/): %s%%)\n" "$overall_health" "$cpu_usage" "$mem_used_percent" "$disk_used_percent"
  if [ "$is_non_healthy" = true ]; then
    exit 1
  else
    exit 0
  fi
fi
