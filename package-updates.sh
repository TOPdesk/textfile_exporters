#!/bin/bash

main() {
  parse_arguments "$@"
  validate_arguments

  prepare_tools
  check_tools

  update_packages_list

  get_regular_and_security_updates
  validate_update_data

  create_text_format_file
}

parse_arguments() {
  while [[ $# -gt 0 ]] ; do
    key="$1"
    case $key in
      -s|--skip-update)
        SKIP_UPDATE="yes"
        ;;
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

validate_arguments() {
  if [ -z "$TEXTFILES" ] ; then
    print_error_and_terminate "Invalid arguments. Use --help for usage."
  fi

  if [ ! -d "$TEXTFILES" ] ; then
    print_error_and_terminate "$TEXTFILES is not a directory. Use --help for usage."
  fi
}

prepare_tools() {
  APT_GET="/usr/bin/apt-get"
  APT_CHECK="/usr/lib/update-notifier/apt-check"
  YUM="/usr/bin/yum"
}

check_tools() {
  if [ ! -x "$APT_CHECK" ] && [ ! -x "$APT_GET" ] && [ ! -x "$YUM" ] ; then
    print_error_and_terminate "Can not find any of apt-check, apt-get or yum."
  fi
}

update_packages_list() {
  if [ -z "$SKIP_UPDATE" ] && [ -x "$APT_GET" ]; then
    "$APT_GET" update >/dev/null 2>&1
    if [ $? -ne 0 ] ; then
      print_error_and_terminate "Could not run apt-get update."
    fi
  fi
}

get_regular_and_security_updates() {
  if [ -x "$APT_CHECK" ] ; then
    get_data_with_apt_check
  else
    if [ -x "$APT_GET" ] ; then
      get_data_with_apt_get
    elif [ -x "$YUM" ]; then
      get_data_with_yum
    fi
  fi
}

get_data_with_apt_check() {
  local AVAILABLE_UPDATES=$($APT_CHECK 2>&1)
  IFS="\;" read ALL_UPDATES SECURITY_UPDATES <<< $AVAILABLE_UPDATES
  REGULAR_UPDATES=$(($ALL_UPDATES - $SECURITY_UPDATES))
}

get_data_with_apt_get() {
  SECURITY_UPDATES="Nan"
  REGULAR_UPDATES="Nan"
  ALL_UPDATES=$($APT_GET -sq upgrade | grep ^Inst\ | wc -l)
}

get_data_with_yum() {
  if [ -z "$SKIP_UPDATE" ] ; then
    CACHEONLY=""
  else
    CACHEONLY="--cacheonly "
  fi
  local AVAILABLE_UPDATES=$(yum list updates --security $CACHEONLY | tail -n 1 | grep -oE "[0-9]+ " | tr -d ' ' | tr '\n' ';')
  IFS="\;" read ALL_UPDATES SECURITY_UPDATES <<< $AVAILABLE_UPDATES
  case $SECURITY_UPDATES in
    (*[!0-9]*|'')
      SECURITY_UPDATES="0"
      ;;
  esac
  REGULAR_UPDATES=$(($ALL_UPDATES - $SECURITY_UPDATES))
}

validate_update_data() {
  case $ALL_UPDATES in
    (*[!0-9]*|'')
      print_error_and_terminate "Invalid package count received for all updates '$ALL_UPDATES'."
      ;;
  esac
  case $REGULAR_UPDATES in
    "Nan")
      ;;
    (*[!0-9]*|'')
      print_error_and_terminate "Invalid package count received for regular updates '$REGULAR_UPDATES'."
      ;;
  esac
  case $SECURITY_UPDATES in
    "Nan")
      ;;
    (*[!0-9]*|'')
      print_error_and_terminate "Invalid package count received for security updates '$SECURITY_UPDATES'."
      ;;
  esac
}

create_text_format_file() {
  TARGET="$TEXTFILES/package-updates.prom"
  echo "" > "$TARGET"
  echo "# HELP updates_total The number of package updates available." >> "$TARGET"
  echo "# TYPE updates_total counter" >> "$TARGET"
  echo -e "updates_total{type=\"security\"}\t$SECURITY_UPDATES" >> "$TARGET"
  echo -e "updates_total{type=\"regular\"} \t$REGULAR_UPDATES" >> "$TARGET"
  echo -e "updates_total{type=\"available\"} \t$ALL_UPDATES" >> "$TARGET"
}

print_help_and_terminate() {
  echo "Usage: $(basename $0) [arguments] <path-to-textfile-directory>"
  echo "Generates or updates System Packgages metrics for Prometheus."
  echo
  echo "Arguments:"
  echo "        -s --skip-updates       Does not update packages list"
  echo
  echo "See --collector.textfile.directory setting of Node Exporter"
  exit 0
}

print_error_and_terminate() {
  echo "$1" >&2
  exit 1
}

main "$@"
