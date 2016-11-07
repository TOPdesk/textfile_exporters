# Introduction

There scripts provide system-specific data that can be consumed by the [Textfile Collector](https://github.com/prometheus/node_exporter/blob/master/README.md#textfile-collector) of [Prometheus](https://prometheus.io) [Node Exporter](https://github.com/prometheus/node_exporter).

Scripts generally require modern bash, and created for Ubuntu (Debian) with CentOS support for some cases. Scripts have their own --help to figure out what's going on.

# Features

### System info
Lives in `system-info.sh`. Provides metrics for OS Release `ID`, `NAME`, and `PRETTY_NAME` from `/etc/os-release` file, and Kernel version from `uname -r`.
```
os_release{type="id"}
os_release{type="name"}
os_release{type="pretty-name"}
kernel_version
```
All provided metrics are untyped.
