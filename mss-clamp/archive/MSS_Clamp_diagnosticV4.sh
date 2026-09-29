#!/bin/bash
# =============================================================================
# Version History
# -----------------------------------------------------------------------------
# v1 - Initial. PPPoE-focused, raw interface dumps (sensitive output).
# v2 - Generalized for any WAN type. Auto-detected from main-table default.
#      Sanitized output. Extended size range to 1252B. Brittle: main table only.
# v3 - Added fallback chain: CLI override, main table, any table, UP ppp*.
#      Bug: 'any table' scan picked first default found, which on UniFi PBR
#      setups was often a VPN tunnel default (proto VPN) instead of real WAN.
# v4 - WAN detection in non-main tables now:
#        (i)  excludes 'proto VPN' routes (UniFi tunnel defaults)
#        (ii) sorts candidates by metric, picks lowest (handles multi-WAN
#             failover where multiple kernel defaults coexist)
#      This correctly handles UCG-Fiber's table naming convention (e.g.
#      201.ppp0) where each WAN gets its own per-interface routing table.
# =============================================================================

set -u

OUT="report.txt"
TARGETS="1.1.1.1 8.8.8.8 9.9.9.9"
SIZES="1472 1464 1452 1440 1428 1412 1400 1392 1380 1372 1352 1300 1272 1252"
COUNT=2
TIMEOUT=3

# ---------- WAN interface detection ----------
WAN_IFACE=""
DETECT_METHOD=""

# (a) CLI argument override
if [ "${1:-}" != "" ]; then
  WAN_IFACE="$1"
  DETECT_METHOD="CLI argument override"
fi

# (b) IPv4 default route in main table
if [ -z "$WAN_IFACE" ]; then
  WAN_IFACE=$(ip route show default 2>/dev/null | grep -oE 'dev [^ ]+' | head -1 | awk '{print $2}')
  [ -n "$WAN_IFACE" ] && DETECT_METHOD="default route (main table)"
fi

# (c) IPv4 default routes across all tables; exclude VPN tunnels; pick lowest metric
# Handles UniFi-style policy-based routing (per-iface tables like 201.ppp0).
if [ -z "$WAN_IFACE" ]; then
  WAN_IFACE=$(ip route show default table all 2>/dev/null | \
    grep -v 'proto VPN' | \
    awk '
      /^default/ {
        iface = ""; metric = 99999
        for (i = 1; i <= NF; i++) {
          if ($i == "dev")    iface = $(i+1)
          if ($i == "metric") metric = $(i+1) + 0
        }
        if (iface != "") print metric, iface
      }
    ' | sort -n | head -1 | awk '{print $2}')
  [ -n "$WAN_IFACE" ] && DETECT_METHOD="default route (PBR table, lowest metric, non-VPN)"
fi

# (d) Last resort: first UP ppp* interface
if [ -z "$WAN_IFACE" ]; then
  WAN_IFACE=$(ip -br link show 2>/dev/null | awk '/^ppp[0-9]+[[:space:]]+UP/ {print $1; exit}')
  [ -n "$WAN_IFACE" ] && DETECT_METHOD="active PPP interface (no default route found)"
fi

if [ -z "$WAN_IFACE" ]; then
  echo "ERROR: Could not detect WAN interface." >&2
  echo "       Tried: CLI arg, main table default, all-table default, UP ppp*." >&2
  echo "       Override manually:  $0 <interface-name>" >&2
  echo "       Example:            $0 ppp0" >&2
  exit 1
fi

# Validate the chosen interface exists
if ! ip link show "$WAN_IFACE" >/dev/null 2>&1; then
  echo "ERROR: Interface '$WAN_IFACE' does not exist on this device." >&2
  echo "       Available interfaces:" >&2
  ip -br link show 2>/dev/null | awk '{print "         " $1}' >&2
  exit 1
fi

WAN_MTU=$(ip link show "$WAN_IFACE" 2>/dev/null | grep -oE 'mtu [0-9]+' | awk '{print $2}')

# ---------- MSS clamp extraction ----------
CURRENT_MSS=$(iptables -t mangle -L -n -v 2>/dev/null | \
  awk -v wan=" $WAN_IFACE " '
    index($0, wan) && /TCPMSS set/ {
      for (i=1; i<=NF; i++) if ($i == "set") { print $(i+1); exit }
    }')

CLAMP_TO_PMTU=""
if [ -z "$CURRENT_MSS" ]; then
  if iptables -t mangle -L -n -v 2>/dev/null | awk -v wan=" $WAN_IFACE " 'index($0, wan) && /clamp/' | grep -q .; then
    CLAMP_TO_PMTU="yes"
  fi
fi

if [ -n "$WAN_MTU" ]; then
  EXPECTED_MSS=$((WAN_MTU - 40))
else
  EXPECTED_MSS=""
fi

# ---------- Report ----------
{
  echo "============================================================"
  echo "WAN Path MTU / MSS Sanity Report"
  echo "Generated: $(date -Is 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)"
  echo "============================================================"
  echo
  echo "WAN interface:         $WAN_IFACE"
  echo "Detection method:      $DETECT_METHOD"
  echo "WAN interface MTU:     ${WAN_MTU:-(unknown)}"
  echo "Expected MSS (MTU-40): ${EXPECTED_MSS:-(unknown)}"
  if [ -n "$CURRENT_MSS" ]; then
    echo "Configured MSS clamp:  $CURRENT_MSS (static)"
  elif [ -n "$CLAMP_TO_PMTU" ]; then
    echo "Configured MSS clamp:  clamp-to-PMTU (dynamic)"
  else
    echo "Configured MSS clamp:  (none detected for $WAN_IFACE)"
  fi
  echo

  if [ -n "$CURRENT_MSS" ] && [ -n "$EXPECTED_MSS" ]; then
    if [ "$CURRENT_MSS" -eq "$EXPECTED_MSS" ]; then
      echo "STATUS: Configured MSS matches interface MTU. Good."
    elif [ "$CURRENT_MSS" -lt "$EXPECTED_MSS" ]; then
      DIFF=$((EXPECTED_MSS - CURRENT_MSS))
      echo "STATUS: Configured MSS is ${DIFF}B BELOW interface-implied value."
      echo "        Conservative - may cost throughput. Sweep below confirms"
      echo "        whether path supports more."
    else
      DIFF=$((CURRENT_MSS - EXPECTED_MSS))
      echo "STATUS: Configured MSS is ${DIFF}B ABOVE interface MTU - 40."
      echo "        WILL cause fragmentation/drops. Reduce to ${EXPECTED_MSS}."
    fi
  fi
  echo

  echo "============================================================"
  echo "DF-ping sweep (largest IP packet that traverses unfragmented)"
  echo "  Sizes (B): $SIZES"
  echo "  Per test:  $COUNT pings, ${TIMEOUT}s timeout, $(echo $TARGETS | wc -w) public anycast targets"
  echo "============================================================"
  echo
  printf "  %-7s | %-9s | %-9s | %-9s\n" "PAYLOAD" "T1" "T2" "T3"
  printf "  %-7s-+-%-9s-+-%-9s-+-%-9s\n" "-------" "---------" "---------" "---------"

  RESULTS=""
  for SZ in $SIZES; do
    SUCCESS=0
    LINE=""
    for T in $TARGETS; do
      PING_OUT=$(ping -M do -s "$SZ" -c "$COUNT" -W "$TIMEOUT" "$T" 2>&1)
      RC=$?
      if [ $RC -eq 0 ] && echo "$PING_OUT" | grep -q " 0% packet loss"; then
        STATUS="OK"
        SUCCESS=$((SUCCESS + 1))
      elif echo "$PING_OUT" | grep -qi "frag needed\|message too long"; then
        STATUS="too-big"
      elif echo "$PING_OUT" | grep -qi "100% packet loss"; then
        STATUS="loss/flt"
      else
        STATUS="err"
      fi
      LINE="$LINE | $(printf '%-9s' "$STATUS")"
    done
    printf "  %-7s%s\n" "${SZ}B" "$LINE"
    RESULTS="$RESULTS $SZ:$SUCCESS"
  done

  echo
  echo "  Legend: OK = round-trip succeeded; too-big = kernel/network refused"
  echo "          (path MTU smaller); loss/flt = no response (rate-limit or filter)"
  echo

  echo "============================================================"
  echo "Summary"
  echo "============================================================"
  LARGEST_OK=""
  for ENTRY in $RESULTS; do
    SZ=${ENTRY%%:*}
    SC=${ENTRY##*:}
    if [ -z "$LARGEST_OK" ] && [ "$SC" -ge 2 ]; then
      LARGEST_OK="$SZ"
    fi
  done

  if [ -n "$LARGEST_OK" ]; then
    EMPIRICAL_PATH_MTU=$((LARGEST_OK + 28))
    EMPIRICAL_MSS=$((LARGEST_OK - 12))
    echo "Largest payload working on majority of targets: ${LARGEST_OK}B"
    echo "Empirical path MTU lower bound:                 ${EMPIRICAL_PATH_MTU}B"
    echo "Empirical MSS upper bound:                      ${EMPIRICAL_MSS}"
    echo
    if [ -n "$WAN_MTU" ] && [ "$WAN_MTU" -le "$EMPIRICAL_PATH_MTU" ]; then
      echo "Local WAN MTU ($WAN_MTU) is at or below empirical path MTU."
      echo "Constraint is the local interface; kernel will refuse larger frames"
      echo "before they leave the device."
      echo "Authoritative MSS = (WAN MTU - 40) = ${EXPECTED_MSS}"
    else
      echo "Path MTU appears constrained upstream of this device."
      echo "Recommended MSS clamp: ${EMPIRICAL_MSS}"
      echo "(Note: sweep resolution is the step between tested payloads;"
      echo " true path MTU may be slightly higher than the lower-bound shown.)"
    fi
  else
    echo "WARNING: No payload size succeeded on majority of targets."
    echo "Possible causes: WAN down, ICMP fully filtered, path MTU below 1280B,"
    echo "or all three public targets unreachable. Investigate manually."
  fi
  echo
  echo "Done. Report sanitized for sharing - contains no IPs, MACs, hostnames,"
  echo "or identifying network details."
} | tee "$OUT"

echo
echo "Report saved to: $OUT"

# v4
