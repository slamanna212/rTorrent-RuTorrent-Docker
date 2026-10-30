# Migrating from the 0.15.x image to this one

This image moved from rTorrent/libtorrent **0.15.3 → 0.16.27**, ruTorrent
**5.2.8 → 5.3.19**, PHP **8.3 → 8.5** and Alpine **3.21 → 3.24**.

Most of it is transparent. One thing is not: **rTorrent 0.16 renamed or removed a
set of config commands**, and `/data/rtorrent/.rtorrent.rc` is *only created if it
does not already exist*. Your existing file survives the upgrade, so any line
using an old command name is now **silently ignored** — no error, no warning in
the UI, the setting just stops applying.

The most damaging case is the incoming port range: it stops being applied and
rTorrent falls back to its built-in default of **6881-6999**, which your NAT
forward almost certainly does not cover.

The container logs a warning at startup when it detects an old-style file:

```
WARNING: /data/rtorrent/.rtorrent.rc uses rTorrent commands removed in 0.16.
         Those lines are IGNORED (no -D). See MIGRATION.md before starting torrents.
```

## Command renames

| Removed / renamed (0.15) | Use instead (0.16) |
|---|---|
| `port_range` | `network.listen.port.range.set` |
| `port_random` | `network.listen.port.random.set` |
| `network.port_range` | `network.listen.port.range` |
| `network.port_random` | `network.listen.port.random` |
| `dht.port.set` | `dht.override_port.set` |
| `schedule2` | `schedule` |
| `schedule_remove2` | `schedule.remove` |
| `execute2` | `execute` |
| `encoding.add` | *removed, delete the line* |
| `bind` | `network.bind_address.set` |
| `ip` | `network.local_address.set` |
| `network.max_open_files.set` | `system.sockets.files.min_alloc.set` |
| `network.open_sockets` | `system.sockets.size` |
| `network.max_open_sockets` | `system.sockets.max_size` |
| `d.multicall2` | `d.multicall` |
| `network.http.proxy_address.set` | `network.proxy.http.set` |

`protocol.encryption.set` still accepts the old flag list (`allow_incoming,try_outgoing,enable_retry`)
through a compatibility shim, but it logs a warning on every start. The 0.16 form is a policy:

```
protocol.encryption.set = deny | allow | prefer | require
protocol.encryption.set = handshake_<policy>, stream_<policy>
```

`trackers.use_udp.set` and `network.port_open` still parse but do nothing — delete them.

## Why not just run with `-D`?

`-D` re-enables the deprecated aliases. It keeps an old config working, but
upstream has stated these go away before 1.0, and every start logs deprecation
errors. This image does **not** pass `-D`.

## Recommended `.rtorrent.rc` for a random port in a fixed range

```
network.listen.port.range.set = 55950-56000
network.listen.port.random.set = yes
```

Make sure the NAT forward on the router covers the **whole** range, since a new
port is picked on every start.

## Checklist

1. Back up `/data/rtorrent/.rtorrent.rc`.
2. Apply the renames above.
3. Pull the new image and start it.
4. Check the log for the `WARNING:` line above — it should be gone.
5. Confirm rTorrent's listening port is inside your forwarded range:
   `docker exec rtorrent-rutorrent sh -c 'grep -c . /dev/null'` then query XMLRPC
   `network.listen.port`, or simply check that an external port tester reports
   your forwarded port as open.

## Other changes worth knowing

* **ruTorrent 5.3** replaced the deprecated GeoIP1 PHP extension with MaxMindDB.
  The `geoip.so` extension is no longer built or loaded; the bundled GeoIP2
  plugin reads `/data/geoip/*.mmdb` instead.
* **ruTorrent 5.3.9+** neutralises the removed `network.port_open` command, so the
  status-bar port indicator works on 0.16 again. `check_port` now uses
  `api4.ipify.org` plus the Globalping/Portchecker APIs instead of scraping
  yougetsignal.com.
* **Session saves** now run in a separate thread (16 downloads in parallel), so a
  large session no longer stalls the UI.
* **Socket limits** are per-category (`system.sockets.*`) instead of global.
* **WebDAV has been removed** from this image (nginx config, port 9000 and its
  healthcheck are gone).
* Custom ruTorrent themes and plugins in `/data/rutorrent/themes` and
  `/data/rutorrent/plugins` are still copied over the image at boot, so a
  Material Design theme keeps working across the upgrade.
