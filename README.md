# Introduction

There scripts provide system-specific data that can be consumed by the [Textfile Collector](https://github.com/prometheus/node_exporter/blob/master/README.md#textfile-collector) of [Prometheus](https://prometheus.io) [Node Exporter](https://github.com/prometheus/node_exporter).

Scripts generally require modern bash, and created for Ubuntu (Debian) with CentOS support in some cases. Scripts have their own --help to figure out what's going on.

# Features

### System info
Lives in `system-info.sh`. Provides metrics for OS Release `ID`, `NAME`, and `PRETTY_NAME` from `/etc/os-release` file, and Kernel version from `uname -r`. Also checks for `/var/run/reboot-required` on Ubuntu and Debian machines. It does not work with CentOS .
```
node_os_release{id,name,pretty_name}
node_kernel{version}
```
All provided metrics are counters, and you can find the values in the label(s). The node_kernel returns Nan in all cases. The node_os_release returns `0`, `1`, or `Nan` respectively if no reboot is needed, reboot is needed, or it can not be determined (e.g. in CentOS).

### Package updates
Lives in `package-updates.sh`. Provides metrics for available package updates from `apt-check`, `yum` or `apt-get`.
If `apt-check` is available, it will be used. On Debian machines it falls back to `apt-get` and only the "any" type is returned - it can not distinguish between security and regular updates.
On CentOS it uses `yum list updates --security` to figure out the number of packgages.

```
node_package_updates{type="security"}
node_package_updates{type="regular"}
node_package_updates{type="any"}
```
All provided metrics are counters, and returning the number of packages, or `Nan`.

##### Triggering
For Ubuntu/Debian machines: Create file `/etc/apt/apt.conf.d/99node_exporter_package_updates` with content
```
DPkg::Post-Invoke { "<path-to-script>/package-updates.sh -s <path-to-textfiles>"; };
```
to automatically update data when updates are fetched or installed.
