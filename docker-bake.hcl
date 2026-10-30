variable "DEFAULT_TAG" {
  default = "rtorrent-rutorrent:local"
}

// Special target: https://github.com/docker/metadata-action#bake-definition
target "docker-metadata-action" {
  tags = ["${DEFAULT_TAG}"]
}

// Default target if none specified
group "default" {
  targets = ["image-local"]
}

target "image" {
  inherits = ["docker-metadata-action"]
}

target "image-local" {
  inherits = ["image"]
  output = ["type=docker"]
}

// amd64 only: the build stages compile rTorrent/libtorrent from source, and the
// arm targets were dropped to keep build time and CI cost down.
target "image-all" {
  inherits = ["image"]
  platforms = [
    "linux/amd64"
  ]
}

target "geoip2-rutorrent-vendor" {
  target = "export-geoip2-rutorrent"
  output = ["type=local,dest=geoip2-rutorrent"]
}
