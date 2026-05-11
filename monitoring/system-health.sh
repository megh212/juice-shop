#!/bin/sh

#
# Copyright (c) 2014-2026 Bjoern Kimminich & the OWASP Juice Shop contributors.
# SPDX-License-Identifier: MIT
#

CPU_LIMIT=${CPU_LIMIT:-60}
MEM_LIMIT=${MEM_LIMIT:-80}
DISK_LIMIT=${DISK_LIMIT:-80}

get_cpu_usage() {
  set -- $(grep '^cpu ' /proc/stat)
  prev_idle=$(( $5 + $6 ))
  prev_total=$(( $2 + $3 + $4 + $5 + $6 + $7 + $8 + $9 ))
  sleep 1
  set -- $(grep '^cpu ' /proc/stat)
  idle=$(( $5 + $6 ))
  total=$(( $2 + $3 + $4 + $5 + $6 + $7 + $8 + $9 ))
  total_diff=$(( total - prev_total ))
  idle_diff=$(( idle - prev_idle ))

  if [ "$total_diff" -eq 0 ]; then
    printf "0"
    return
  fi

  printf "%s" $(( (100 * (total_diff - idle_diff)) / total_diff ))
}

get_memory_usage() {
  mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
  mem_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)

  if [ -z "$mem_total" ] || [ -z "$mem_available" ]; then
    printf "0"
    return
  fi

  mem_used=$((mem_total - mem_available))
  printf "%s" $(( (100 * mem_used) / mem_total ))
}

get_disk_usage() {
  df -P / | awk 'NR==2 {gsub(/%/,"",$5); print $5}'
}

cpu_usage=$(get_cpu_usage)
memory_usage=$(get_memory_usage)
disk_usage=$(get_disk_usage)

printf "CPU Usage: %s%%\n" "$cpu_usage"
printf "Memory Usage: %s%%\n" "$memory_usage"
printf "Disk Usage: %s%%\n" "$disk_usage"

issues=""
if [ "$cpu_usage" -ge "$CPU_LIMIT" ]; then
  issues="CPU"
fi
if [ "$memory_usage" -ge "$MEM_LIMIT" ]; then
  issues="${issues:+$issues, }Memory"
fi
if [ "$disk_usage" -ge "$DISK_LIMIT" ]; then
  issues="${issues:+$issues, }Disk"
fi

if [ -z "$issues" ]; then
  printf "healthy\n"
else
  printf "unhealthy (%s usage above limit)\n" "$issues"
fi
