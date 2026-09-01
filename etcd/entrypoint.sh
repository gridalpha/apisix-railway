#!/bin/sh
#
# etcd for Apache APISIX on Railway.
#
# Two jobs the upstream distroless image cannot do: create the data directory one
# level below the volume mount root (every Railway volume ships a lost+found), and
# turn on etcd's RBAC so nothing else on the project's private network can rewrite
# the gateway's configuration.
#
set -eu

: "${ETCD_DATA_DIR:=/var/lib/etcd/data}"
export ETCD_DATA_DIR
mkdir -p "$ETCD_DATA_DIR"

EP="http://127.0.0.1:${ETCD_CLIENT_PORT:-2379}"

if [ -n "${ETCD_ROOT_PASSWORD:-}" ]; then
    (
        i=0
        while [ "$i" -lt 60 ]; do
            if etcdctl --endpoints="$EP" --command-timeout=3s endpoint status >/dev/null 2>&1 ||
               etcdctl --endpoints="$EP" --user "root:${ETCD_ROOT_PASSWORD}" \
                       --command-timeout=3s endpoint status >/dev/null 2>&1; then
                break
            fi
            i=$((i + 1))
            sleep 2
        done

        if etcdctl --endpoints="$EP" --user "root:${ETCD_ROOT_PASSWORD}" auth status 2>/dev/null |
           grep -qi 'Authentication Status: true'; then
            echo "[bootstrap] etcd authentication is already enabled"
        else
            echo "[bootstrap] enabling etcd authentication"
            etcdctl --endpoints="$EP" user add root \
                    --new-user-password="$ETCD_ROOT_PASSWORD" >/dev/null 2>&1 ||
            etcdctl --endpoints="$EP" user passwd root --interactive=false \
                    --new-user-password="$ETCD_ROOT_PASSWORD" >/dev/null 2>&1 || true
            etcdctl --endpoints="$EP" user grant-role root root >/dev/null 2>&1 || true
            if etcdctl --endpoints="$EP" auth enable >/dev/null 2>&1; then
                echo "[bootstrap] etcd authentication enabled"
            else
                echo "[bootstrap] WARNING: could not enable etcd authentication"
            fi
        fi
    ) &
else
    echo "[bootstrap] ETCD_ROOT_PASSWORD is unset - etcd will accept unauthenticated clients"
fi

exec etcd "$@"
