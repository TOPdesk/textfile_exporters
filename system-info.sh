#!/bin/bash

main() {
  parse_arguments "$@"
  validate_arguments

  prepare_tools
  check_tools

  get_system_info
  validate_update_data

  create_text_format_file
}

parse_arguments() {
  while [[ $# -gt 0 ]] ; do
    key="$1"
    case $key in
      -h|--help)
        print_help_and_terminate
        ;;
      *)
        if [ -z "$TEXTFILES" ] ; then
          TEXTFILES="$1"
        else
          print_error_and_terminate "Invalid arguments. Use --help for usage."
        fi
        ;;
    esac
    shift
  done
}

prepare_tools() {
  OS_RELEASE="/etc/os-release"
  UNAME=$(which uname)
}

check_tools() {
  if [ ! -r "$OS_RELEASE" ] ; then
    print_error_and_terminate "Can not find /etc/os-release"
  fi
  if [ ! -x "$UNAME" ] ; then
    print_error_and_terminate "Can not find uname"
  fi
}

validate_arguments() {
  if [ -z "$TEXTFILES" ] ; then
    print_error_and_terminate "Invalid arguments. Use --help for usage."
  fi

  if [ ! -d "$TEXTFILES" ] ; then
    print_error_and_terminate "$TEXTFILES is not a directory. Use --help for usage."
  fi
}

get_system_info() {
  SYSTEM_ID=$(cat "$OS_RELEASE" | sed -n 's/^ID=\"\?\([^"]\+\).*$/\1/p')
  SYSTEM_NAME=$(cat "$OS_RELEASE" | sed -n 's/^NAME=\"\?\([^"]\+\).*$/\1/p')
  SYSTEM_PRETTY_NAME=$(cat "$OS_RELEASE" | sed -n 's/^PRETTY_NAME=\"\?\([^"]\+\).*$/\1/p')
  KERNEL_VERSION=$(uname -r)
}

create_text_format_file() {
  TARGET="$TEXTFILES/system-info.prom"
  TIMESTAMP=$(date +"%s")000
  echo "" > "$TARGET"
  echo    "# HELP os_release OS Release informations" >> "$TARGET"
  echo    "# TYPE os_release untyped" >> "$TARGET"
  echo -e "os_release{type=\"id\"}\t$SYSTEM_ID\t$TIMESTAMP" >> "$TARGET"
  echo -e "os_release{type=\"name\"}\t$SYSTEM_NAME\t$TIMESTAMP" >> "$TARGET"
  echo -e "os_release{type=\"pretty-name\"}\t$SYSTEM_PRETTY_NAME\t$TIMESTAMP" >> "$TARGET"
  echo    "# HELP kernel_version Kernel version" >> "$TARGET"
  echo    "# TYPE kernel_version untyped" >> "$TARGET"
  echo -e "kernel_version\t$KERNEL_VERSION\t$TIMESTAMP" >> "$TARGET"
}

validate_update_data() {
  if [ -z "$SYSTEM_ID" ] ; then
    print_error_and_terminate "Can not determine ID from os-release"
  fi
  if [ -z "$SYSTEM_NAME" ] ; then
    print_error_and_terminate "Can not determine NAME from os-release"
  fi
  if [ -z "$SYSTEM_PRETTY_NAME" ] ; then
    print_error_and_terminate "Can not determine PRETTY_NAME from os-release"
  fi
  if [ -z "$KERNEL_VERSION" ] ; then
    print_error_and_terminate "Can not determine kernel version from uname -r"
  fi
}

print_help_and_terminate() {
  echo "Usage: $(basename $0) <path-to-textfile-directory>"
  echo "Generates or updates System Info metrics for Prometheus."
  echo ""
  echo "See --collector.textfile.directory setting of Node Exporter"
  exit 0
}

print_error_and_terminate() {
  echo "$1" >&2
  exit 1
}

main "$@"
