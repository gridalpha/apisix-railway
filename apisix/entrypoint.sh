#!/usr/bin/env bash
#
# Railway has no service dependency ordering, so APISIX's own `apisix init_etcd`
# step races etcd on a first deploy. Wait for the etcd client port before handing
# over to the image's entrypoint; give up after the loop so a genuinely missing
# etcd still surfaces as APISIX's own error rather than a hang.
#
set -euo pipefail

URL="${APISIX_ETCD_URL:-http://etcd.railway.internal:2379}"
HOSTPORT="${URL#*://}"
HOSTPORT="${HOSTPORT%%/*}"
HOST="${HOSTPORT%%:*}"
PORT_="${HOSTPORT##*:}"
[ "$PORT_" = "$HOST" ] && PORT_=2379

echo "[railway] waiting for etcd at ${HOST}:${PORT_}"
for i in $(seq 1 60); do
    if (exec 3<>"/dev/tcp/${HOST}/${PORT_}") 2>/dev/null; then
        echo "[railway] etcd reachable after ${i} attempt(s)"
        break
    fi
    sleep 2
done

exec /docker-entrypoint.sh docker-start
