<p align="center"><a href="https://github.com/crazy-max/docker-rtorrent-rutorrent" target="_blank"><img height="128" src="https://raw.githubusercontent.com/crazy-max/docker-rtorrent-rutorrent/master/.github/docker-rtorrent-rutorrent.jpg"></a></p>

<p align="center">
  <a href="https://hub.docker.com/r/crazymax/rtorrent-rutorrent/tags?page=1&ordering=last_updated"><img src="https://img.shields.io/github/v/tag/crazy-max/docker-rtorrent-rutorrent?label=version&style=flat-square" alt="Latest Version"></a>
  <a href="https://github.com/crazy-max/docker-rtorrent-rutorrent/actions?workflow=build"><img src="https://img.shields.io/github/actions/workflow/status/crazy-max/docker-rtorrent-rutorrent/build.yml?branch=master&label=build&logo=github&style=flat-square" alt="Build Status"></a>
  <a href="https://hub.docker.com/r/crazymax/rtorrent-rutorrent/"><img src="https://img.shields.io/docker/stars/crazymax/rtorrent-rutorrent.svg?style=flat-square&logo=docker" alt="Docker Stars"></a>
  <a href="https://hub.docker.com/r/crazymax/rtorrent-rutorrent/"><img src="https://img.shields.io/docker/pulls/crazymax/rtorrent-rutorrent.svg?style=flat-square&logo=docker" alt="Docker Pulls"></a>
  <br /><a href="https://github.com/sponsors/crazy-max"><img src="https://img.shields.io/badge/sponsor-crazy--max-181717.svg?logo=github&style=flat-square" alt="Become a sponsor"></a>
  <a href="https://www.paypal.me/crazyws"><img src="https://img.shields.io/badge/donate-paypal-00457c.svg?logo=paypal&style=flat-square" alt="Donate Paypal"></a>
</p>

## About

[rTorrent](https://github.com/rakshasa/rtorrent) with [ruTorrent](https://github.com/Novik/ruTorrent)
Docker image.

> [!TIP] 
> Want to be notified of new releases? Check out 🔔 [Diun (Docker Image Update Notifier)](https://github.com/crazy-max/diun)
> project!

___

* [Features](#features)
* [Build locally](#build-locally)
* [Image](#image)
* [Environment variables](#environment-variables)
  * [General](#general)
  * [rTorrent](#rtorrent)
  * [ruTorrent](#rutorrent)
* [Volumes](#volumes)
* [Ports](#ports)
* [Usage](#usage)
  * [Docker Compose](#docker-compose)
  * [Command line](#command-line)
* [Notes](#notes)
  * [XMLRPC through nginx](#xmlrpc-through-nginx)
  * [Populate .htpasswd files](#populate-htpasswd-files)
  * [Bootstrap config `.rtlocal.rc`](#bootstrap-config-rtlocalrc)
  * [Override or add a ruTorrent plugin/theme](#override-or-add-a-rutorrent-plugintheme)
  * [Edit a ruTorrent plugin configuration](#edit-a-rutorrent-plugin-configuration)
  * [Increase Docker timeout to allow rTorrent to shutdown gracefully](#increase-docker-timeout-to-allow-rtorrent-to-shutdown-gracefully)
  * [WAN IP address](#wan-ip-address)
  * [Configure rTorrent session saving](#configure-rtorrent-session-saving)
  * [Configure rTorrent tracker scrape](#rtorrent-tracker-scrape-patch)
  * [Configure rTorrent send receive buffers](#rtorrent-send-receive-buffers)
  * [Configure rTorrent disk space preallocation](#rtorrent-disk-space-preallocation)
* [Upgrade](#upgrade)
* [Contributing](#contributing)
* [License](#license)

## Features

* Run as non-root user
* Multi-platform image
* Latest [rTorrent](https://github.com/rakshasa/rtorrent) / [libTorrent](https://github.com/rakshasa/libtorrent) release compiled from source
* Latest [ruTorrent](https://github.com/Novik/ruTorrent) release
* Domain name resolving enhancements with [c-ares](https://github.com/rakshasa/rtorrent/wiki/Performance-Tuning#rtrorrent-with-c-ares) and [UDNS](https://www.corpit.ru/mjt/udns.html) for asynchronous DNS requests
* Enhanced [rTorrent config](rootfs/tpls/.rtorrent.rc) and bootstraping with a [local config](rootfs/tpls/etc/rtorrent/.rtlocal.rc)
* XMLRPC through nginx over SCGI socket (basic auth optional)
* Ability to add a custom ruTorrent plugin / theme
* Allow persisting specific configuration for ruTorrent plugins
* ruTorrent [GeoIP2 plugin](https://github.com/Micdu70/geoip2-rutorrent)
* [mktorrent](https://github.com/pobrn/mktorrent) installed for ruTorrent create plugin
* [Traefik](https://github.com/containous/traefik-library-image) Docker image as reverse proxy and creation/renewal of Let's Encrypt certificates (see [this template](examples/traefik))
* [geoip-updater](https://github.com/crazy-max/geoip-updater) Docker image to download MaxMind's GeoIP2 databases on a time-based schedule for geolocation

## Build locally

```shell
git clone https://github.com/crazy-max/docker-rtorrent-rutorrent.git
cd docker-rtorrent-rutorrent

# Build image and output to docker (default)
docker buildx bake

# Build image
docker buildx bake image

# Build multi-platform image
docker buildx bake image-all
```

## Image

| Registry                                                                                                      | Image                                   |
|---------------------------------------------------------------------------------------------------------------|-----------------------------------------|
| [Docker Hub](https://hub.docker.com/r/crazymax/rtorrent-rutorrent/)                                           | `crazymax/rtorrent-rutorrent`           |
| [GitHub Container Registry](https://github.com/users/crazy-max/packages/container/package/rtorrent-rutorrent) | `ghcr.io/crazy-max/rtorrent-rutorrent`  |

Following platforms for this image are available:

```
$ docker buildx imagetools inspect crazymax/rtorrent-rutorrent --format "{{json .Manifest}}" | \
  jq -r '.manifests[] | select(.platform.os != null and .platform.os != "unknown") | .platform | "\(.os)/\(.architecture)\(if .variant then "/" + .variant else "" end)"'

linux/amd64
linux/arm/v6
linux/arm/v7
linux/arm64
```


## Environment variables

### General

* `TZ`: The timezone assigned to the container (default `UTC`)
* `PUID`: rTorrent user id (default `1000`)
* `PGID`: rTorrent group id (default `1000`)
* `WAN_IP`: [Public IP address](#wan-ip-address) reported to the tracker (auto if empty)
* `WAN_IP_CMD`: Command to resolve the [Public IP address](#wan-ip-address)
* `MEMORY_LIMIT`: PHP memory limit (default `256M`)
* `UPLOAD_MAX_SIZE`: Upload max size (default `16M`)
* `CLEAR_ENV`: Clear environment in FPM workers (default `yes`)
* `OPCACHE_MEM_SIZE`: PHP OpCache memory consumption (default `128`)
* `MAX_FILE_UPLOADS`: The maximum number of files allowed to be uploaded simultaneously (default `50`)
* `AUTH_DELAY`: The time in seconds to wait for Basic Auth (default `0s`)
* `REAL_IP_FROM`: Trusted addresses that are known to send correct replacement addresses (default `0.0.0.0/32`)
* `REAL_IP_HEADER`: Request header field whose value will be used to replace the client address (default `X-Forwarded-For`)
* `LOG_IP_VAR`: Use another variable to retrieve the remote IP address for access [log_format](http://nginx.org/en/docs/http/ngx_http_log_module.html#log_format) on Nginx. (default `remote_addr`)
* `LOG_ACCESS`: Output access log (default `true`)
* `XMLRPC_AUTHBASIC_STRING`: Message displayed during validation of XMLRPC Basic Auth (default `rTorrent XMLRPC restricted access`)
* `XMLRPC_PORT`: XMLRPC port through nginx over SCGI socket (default `8000`)
* `XMLRPC_SIZE_LIMIT`: Maximum body size of XMLRPC calls (default `1M`)
* `RUTORRENT_AUTHBASIC_STRING`: Message displayed during validation of ruTorrent Basic Auth (default `ruTorrent restricted access`)
* `RUTORRENT_PORT`: ruTorrent HTTP port (default `8080`)

### rTorrent

* `RT_LOG_LEVEL`: rTorrent log level (default `info`)
* `RT_LOG_EXECUTE`: Log executed commands to `/data/rtorrent/log/execute.log` (default `false`)
* `RT_LOG_XMLRPC`: Log XMLRPC queries to `/data/rtorrent/log/xmlrpc.log` (default `false`)
* `RT_SESSION_SAVE_SECONDS`: Seconds between writing torrent information to disk (default `3600`)
* `RT_TRACKER_DELAY_SCRAPE`: Delay tracker announces at startup (default `true`)
* `RT_DHT_PORT`: DHT UDP port (`dht.port.set`, default `6881`)
* `RT_INC_PORT`: Incoming connections (`network.port_range.set`, default `50000`)
* `RT_SEND_BUFFER_SIZE`: Sets default tcp wmem value (`network.send_buffer.size.set`, default `4M`)
* `RT_RECEIVE_BUFFER_SIZE`: Sets default tcp rmem value (`network.receive_buffer.size.set`, default `4M`)
* `RT_PREALLOCATE_TYPE`: Sets the type of [disk space preallocation](#rtorrent-disk-space-preallocation) (default `0`)

### ruTorrent

* `RU_REMOVE_CORE_PLUGINS`: Comma separated list of core plugins to remove ; set to `false` to disable removal 
* `RU_HTTP_USER_AGENT`: ruTorrent HTTP user agent (default `Mozilla/5.0 (Windows NT 6.0; WOW64; rv:12.0) Gecko/20100101 Firefox/12.0`)
* `RU_HTTP_TIME_OUT`: ruTorrent HTTP timeout in seconds (default `30`)
* `RU_HTTP_USE_GZIP`: Use HTTP Gzip compression (default `true`)
* `RU_RPC_TIME_OUT`: ruTorrent RPC timeout in seconds (default `5`)
* `RU_LOG_RPC_CALLS`: Log ruTorrent RPC calls (default `false`)
* `RU_LOG_RPC_FAULTS`: Log ruTorrent RPC faults (default `true`)
* `RU_PHP_USE_GZIP`: Use PHP Gzip compression (default `false`)
* `RU_PHP_GZIP_LEVEL`: PHP Gzip compression level (default `2`)
* `RU_SCHEDULE_RAND`: Rand for schedulers start, +0..X seconds (default `10`)
* `RU_LOG_FILE`: ruTorrent log file path for errors messages (default `/data/rutorrent/rutorrent.log`)
* `RU_DO_DIAGNOSTIC`: ruTorrent diagnostics like permission checking (default `true`)
* `RU_CACHED_PLUGIN_LOADING`: Set to `true` to enable rapid cached loading of ruTorrent plugins (default `false`)
* `RU_SAVE_UPLOADED_TORRENTS`: Save torrents files added wia ruTorrent in `/data/rutorrent/share/torrents` (default `true`)
* `RU_OVERWRITE_UPLOADED_TORRENTS`: Existing .torrent files will be overwritten (default `false`)
* `RU_FORBID_USER_SETTINGS`: If true, allows for single user style configuration, even with webauth (default `false`)
* `RU_LOCALE`: Set default locale for ruTorrent (default `UTF8`)

## Volumes

* `/data`: rTorrent / ruTorrent config, session files, log, ...
* `/downloads`: Downloaded files
* `/passwd`: Contains htpasswd files for basic auth

> :warning: Note that the volumes should be owned by the user/group with the specified `PUID` and `PGID`. If you don't
> give the volumes correct permissions, the container may not start.

## Ports

* `6881` (or `RT_DHT_PORT`): DHT UDP port (`dht.port.set`)
* `8000` (or `XMLRPC_PORT`): XMLRPC port through nginx over SCGI socket
* `8080` (or `RUTORRENT_PORT`): ruTorrent HTTP port
* `50000` (or `RT_INC_PORT`): Incoming connections (`network.port_range.set`)

> :warning: Port p+1 defined for `XMLRPC_PORT`, `RUTORRENT_PORT` will also be reserved for
> healthcheck. (e.g. if you define `RUTORRENT_PORT=8080`, port `8081` will be reserved)

## Usage

### Docker Compose

Docker compose is the recommended way to run this image. Copy the content of
folder [examples/compose](examples/compose) in `/var/rtorrent-rutorrent/` on
your host for example. Edit the compose file with your preferences and run the
following command:

```shell
mkdir data downloads passwd
chown ${PUID}:${PGID} data downloads passwd
docker compose up -d
docker compose logs -f
```

### Command line

You can also use the following minimal command:

```shell
mkdir data downloads passwd
chown ${PUID}:${PGID} data downloads passwd
docker run -d --name rtorrent_rutorrent \
  --ulimit nproc=65535 \
  --ulimit nofile=32000:40000 \
  -p 6881:6881/udp \
  -p 8000:8000 \
  -p 8080:8080 \
  -p 9000:9000 \
  -p 50000:50000 \
  -v $(pwd)/data:/data \
  -v $(pwd)/downloads:/downloads \
  -v $(pwd)/passwd:/passwd \
  crazymax/rtorrent-rutorrent:latest
```

## Notes

### XMLRPC through nginx

rTorrent 0.9.7+ has a built-in daemon mode disabling the user interface, so you
can only control it via XMLRPC. Nginx will route XMLRPC requests to rtorrent
through port `8000`. These requests can be secured with basic authentication
through the `/passwd/rpc.htpasswd` file in which you will need to add a username
with his password. See below to populate this file with a user / password.

### Populate .htpasswd files

For ruTorrent basic auth, XMLRPC through nginx,
you can populate `.htpasswd` files with the following command:


Htpasswd files used:

* `rpc.htpasswd`: XMLRPC through nginx
* `rutorrent.htpasswd`: ruTorrent basic auth

### Bootstrap config `.rtlocal.rc`

When rTorrent is started the bootstrap config [/etc/rtorrent/.rtlocal.rc](rootfs/tpls/etc/rtorrent/.rtlocal.rc)
is imported. This configuration cannot be changed unless you rebuild the image
or overwrite these elements in your `.rtorrent.rc`. Here are the particular
properties of this file:

* `system.daemon.set = true`: Launcher rTorrent as a daemon
* A config layout for the rTorrent's instance you can use in your `.rtorrent.rc`:
  * `cfg.basedir`: Home directory of rtorrent (`/data/rtorrent/`)
  * `cfg.download`: Download directory (`/downloads/`)
  * `cfg.download_complete`: Completed downloads (`/downloads/complete/`)
  * `cfg.download_temp`:  Downloads in progress (`/downloads/temp/`)
  * `cfg.logs`: Logs directory (`/data/rtorrent/log/`)
  * `cfg.session`: Session directory (`/data/rtorrent/.session/`)
  * `cfg.watch`: Watch directory for torrents (`/data/rtorrent/watch/`)
  * `cfg.rundir`: Runtime data of rtorrent (`/var/run/rtorrent/`)
* `d.data_path`: Config var to get the full path of data of a torrent (workaround for the possibly empty `d.base_path` attribute)
* `directory.default.set`: Default directory to save the downloaded torrents (`cfg.download_temp`)
* `session.path.set`: Default session directory (`cfg.session`)
* PID file to `/var/run/rtorrent/rtorrent.pid`
* `network.scgi.open_local`: SCGI local socket and make it group-writable and secure
* `network.port_range.set`: Listening port for incoming peer traffic (`50000-50000`)
* `dht.port.set`: UDP port to use for DHT (`6881`)
* `log.open_file`: Default logging to `/data/rtorrent/log/rtorrent.log`
  * Log level can be modified with the environment variable `RT_LOG_LEVEL`
  * `rpc_events` are logged be default
  * To log executed commands, add the environment variable `RT_LOG_EXECUTE`
  * To log XMLRPC queries, add the environment variable `RT_LOG_XMLRPC`

### Override or add a ruTorrent plugin/theme

You can add a plugin for ruTorrent in `/data/rutorrent/plugins/`. If you add a
plugin that already exists in ruTorrent, it will be removed from ruTorrent core
plugins and yours will be used. And you can also add a theme in `/data/rutorrent/themes/`.
The same principle as for plugins will be used if you want to override one.

> :warning: Container has to be restarted to propagate changes

### Edit a ruTorrent plugin configuration

As you probably know, plugin configuration is not outsourced in ruTorrent.
Loading the configuration of a plugin is done via a `conf.php` file placed at
the root of the plugin folder. To solve this issue with Docker, a special folder
has been created in `/data/rutorrent/plugins-conf` to allow you to configure
plugins. For example to configure the `diskspace` plugin, you will need to create
the `/data/rutorrent/plugins-conf/diskspace.php` file with your configuration:

```php
<?php

$diskUpdateInterval = 10;	// in seconds
$notifySpaceLimit = 512;	// in Mb
$partitionDirectory = null;	// if null, then we will check rtorrent download directory (or $topDirectory if rtorrent is unavailable)
				// otherwise, set this to the absolute path for checked partition. 
```

> :warning: Container has to be restarted to propagate changes

### Increase Docker timeout to allow rTorrent to shutdown gracefully

After issuing a shutdown command, Docker waits 10 seconds for the container to
exit before it is killed.  If you are a seeding many torrents, rTorrent may be
unable to gracefully close within that time period.  As a result, rTorrent is
closed forcefully and the lockfile isn't removed. This stale lockfile will
prevent rTorrent from restarting until the lockfile is removed manually.

The timeout period can be extended by either adding the parameter `-t XX` to
the docker command or `stop_grace_period: XXs` in `compose.yml`, where
`XX` is the number of seconds to wait for a graceful shutdown.

### WAN IP address

`WAN_IP` is the public IP address sent to the tracker. In the majority of cases
you don't need to set it as it will be automatically determined by the tracker.  

But it can be sometimes required to enforce the public IP address when you
are behind a VPN where an erroneous IP is sometimes reported.

You can also use the `WAN_IP_CMD` environment variable to specify a command to
resolve your public IP address. Here are some commands you can use:

* `dig +short myip.opendns.com @resolver1.opendns.com`
* `curl -s ifconfig.me`
* `curl -s ident.me` 

### Configure rTorrent session saving

`RT_SESSION_SAVE_SECONDS` is the seconds between writing torrent information to
disk. The default is 3600 seconds which equals 1 hour. rTorrent has a bad
default of 20 minutes. Twenty minutes is bad for the lifespan of SSDs and
greatly reduces torrent throughput.

It is no longer possible to lose torrents added through ruTorrent on this
docker container. Only torrent statistics are lost during a crash. (Ratio,
Total Uploaded & Downloaded etc.)

Higher values will reduce disk usage, at the cost of minor stat loss during a
crash. Consider increasing to 10800 seconds (3 hours) if running thousands of
torrents.

### rTorrent tracker scrape patch

`RT_TRACKER_DELAY_SCRAPE` specifies whether to delay tracker announces at
rTorrent startup. The default value is `true`. There are two main benefits to
keeping this feature enabled:

1) Software Stability: rTorrent will not crash or time-out with tens of thousands of trackers.
2) Immediate Access: ruTorrent can be accessed immediately after rTorrent is started.

### rTorrent send receive buffers

Overriding the default TCP rmem and wmem values for rTorrent improves torrent
throughput.

* `RT_SEND_BUFFER_SIZE`: Sets default tcp wmem value for the socket.
* `RT_RECEIVE_BUFFER_SIZE`: Sets default tcp rmem value for the socket.

Recommended values:
* `2GB of less system memory`: Reduce to 1M send and 1M receive regardless of speed.
* `4GB to 16GB of system memory`: Keep at default values of 4M send and 4M receive.
* `16GB to 32GB of system memory`: Increase to 8M send for 500Mbps speeds.
* `32GB to 64GB of system memory`: Increase to 16M send for 1G speeds.
* `64GB to 128GB of system memory`: Increase to 32M send for 2.5G speeds.
* `128GB to 256GB of system memory`: Increase to 64M send for 10G speeds.

Memory is better spent elsewhere except under limited circumstances for high
memory and speed conditions. The default values should not be increased, unless
both the memory and speed requirements are met. These values of system memory
are also recommended based on the port speed for rTorrent to reduce disk usage.

### rTorrent disk space preallocation

Preallocate disk space for contents of a torrent

* `RT_PREALLOCATE_TYPE`: Sets the type of disk space preallocation to use.

Acceptable values:
* `0 = disabled (default value)`
* `1 = enabled, allocate when a file is opened for write`
* `2 = enabled, allocate space for the whole torrent at once`

This feature is disabled by default becuase it only benefits HDDs.
By allocating files in sequence we can increase the read speed for seeding.

The first type "1" only allocates disk space for files which start downloading.
Use where disk space is more important than speed. Or you intend to download selective torrent files.

The second type "2" allocates disk space for the entire torrent, whether it's downloaded or not.
This method is faster than "1" becuase it reduces random reads for the entire torrent.
Use where speed is more important than disk space. Or you intend to download 100% of every torrent.

## Upgrade

To upgrade, pull the newer image and launch the container:

```shell
docker compose pull
docker compose up -d
```

## Contributing

Want to contribute? Awesome! The most basic way to show your support is to star
the project, or to raise issues. You can also support this project by [**becoming a sponsor on GitHub**](https://github.com/sponsors/crazy-max)
or by making a [PayPal donation](https://www.paypal.me/crazyws) to ensure this
journey continues indefinitely!

Thanks again for your support, it is much appreciated! :pray:

## License

MIT. See `LICENSE` for more details.
