#!/usr/bin/env bash
cpu=$(top -l 1 -n 0 | awk '/CPU usage/ {gsub(/%/,""); printf "%.0f%%", $3+$5}')
mem=$(vm_stat | awk '
  /Pages active/              { a = int($3) }
  /Pages wired down/          { w = int($4) }
  /occupied by compressor/    { c = int($5) }
  END { printf "%.1fG", (a + w + c) * 4096 / 1073741824 }
')
printf "CPU %s  MEM %s" "$cpu" "$mem"
