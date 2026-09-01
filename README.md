# Apache APISIX on Railway

Deployment sources for [Apache APISIX](https://apisix.apache.org/) — a cloud-native
API gateway — and the etcd configuration store it runs on.

Three images are built from this one repository. Each Railway service picks its
Dockerfile with `RAILWAY_DOCKERFILE_PATH`, and every build uses the repository root
as its context.

| Dockerfile | Service | Public | Ports |
|---|---|---|---|
| `Dockerfile` | `apisix` — the gateway | yes, on 9080 | 9080 proxy, 9180 Admin API + dashboard, 7085 status, 9092 control (loopback) |
| `Dockerfile.etcd` | `etcd` — configuration store | no | 2379 client, 2380 peer |
| `Dockerfile.admin` | `apisix-dashboard` — Caddy in front of the Admin API | yes | `$PORT` |

## Why three services

Railway's edge routes strictly by host and names one public host per service, so
the gateway's traffic port and the Admin API cannot share a domain. `apisix` keeps
9080; `apisix-dashboard` is a small Caddy proxy that publishes 9180, where APISIX
3.13+ serves both the Admin API and its embedded dashboard at `/ui/`.

etcd is a separate service because APISIX stores every route, upstream, consumer
and plugin configuration there, and a gateway that keeps its configuration in the
container would lose it on the next deploy.

## Configuration

`apisix/config.yaml` is committed and reads every per-deployment value through
APISIX's own `${{VAR}}` environment interpolation. Variables written without a
`:=` default are mandatory and APISIX refuses to start without them.

| Variable | Service | Notes |
|---|---|---|
| `APISIX_ADMIN_KEY` | apisix | Admin API key. Also what the dashboard asks for. |
| `APISIX_KEYRING` | apisix | Encrypts SSL keys and plugin secrets in etcd. Exactly 16 or 32 characters, and must never change once data exists. |
| `APISIX_ETCD_URL` | apisix | etcd client URL. |
| `APISIX_ETCD_USER` / `APISIX_ETCD_PASSWORD` | apisix | etcd RBAC credentials. |
| `APISIX_WORKER_PROCESSES` | apisix | Defaults to 2. `auto` would read the host's core count, not the container's quota. |
| `APISIX_ENABLE_IPV6` | apisix | Defaults to true, matching Railway's IPv6-first private network. |
| `APISIX_ENABLE_SSL` | apisix | Defaults to false; Railway's edge terminates TLS. |
| `APISIX_ADMIN_CORS` | apisix | Defaults to false; the dashboard is same-origin. |
| `ETCD_ROOT_PASSWORD` | etcd | Enables etcd RBAC at first boot. Leave it set. |
| `APISIX_ADMIN_UPSTREAM` | apisix-dashboard | `http://<apisix>.railway.internal:9180`. |

## Licence

Apache APISIX and etcd are Apache-2.0. The files in this repository are provided
under the same licence.
