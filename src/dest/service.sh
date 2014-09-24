#!/usr/bin/env sh
#
# SABnzbd service

# import DroboApps framework functions
. /etc/service.subr

# DroboApp framework version
framework_version="2.0"

# app description
name="sabnzbd"
version="0.7.x"
description="Usenet downloader"

# framework-mandated variables
pidfile="/tmp/DroboApps/${name}/pid.txt"
logfile="/tmp/DroboApps/${name}/log.txt"
statusfile="/tmp/DroboApps/${name}/status.txt"
errorfile="/tmp/DroboApps/${name}/error.txt"

# app-specific variables
prog_dir=`dirname \`realpath $0\``
python="${DROBOAPPS_DIR}/python2/bin/python"
conffile="${prog_dir}/data/sabnzbd.ini"
if [[ ! -f "${conffile}" ]]; then
  pidfile="${prog_dir}/var/sabnzbd-8080.pid"
else
  eval "`grep ^port ${conffile} | head -n 1 | sed \"s/ //g\"`"
  pidfile="${prog_dir}/var/sabnzbd-${port}.pid"
fi

# script hardening
set -o errexit  # exit on uncaught error code
set -o nounset  # exit on unset variable
set -o pipefail # propagate last error code on pipe

# ensure log folder exists
logfolder="$(dirname ${logfile})"
[[ ! -d "${logfolder}" ]] && mkdir -p "${logfolder}"

# redirect all output to logfile
exec 3>&1 1>> "${logfile}" 2>&1

# log current date, time, and invocation parameters
echo $(date +"%Y-%m-%d %H-%M-%S"): ${0} ${@}

# enable script tracing
set -o xtrace

start() {
  chmod a+rw /dev/null /dev/full /dev/random /dev/urandom /dev/tty /dev/ptmx /dev/zero /dev/crypto
  rm -f "${pidfile}"
  "${python}" "${prog_dir}/app/SABnzbd.py" -s 0.0.0.0 -f "${conffile}" -d --pid "${prog_dir}/var/"
}

_service_start() {
  # disable error code and unset variable checks
  set +e
  set +u
  # /etc/service.subr uses DROBOAPPS without setting it first
  DROBOAPPS=""
  # 
  start_service
  set -u
  set -e
}

_service_stop() {
  /sbin/start-stop-daemon -K -x "${python}" -p "${pidfile}" -v || echo "${name} is not running" >&3
}

_service_restart() {
  service_stop
  sleep 3
  service_start
}

_service_status() {
  status >&3
}

_service_help() {
  echo "Usage: $0 [start|stop|restart|status]" >&3
  set +e
  exit 1
}

case "${1:-}" in
  start|stop|restart|status) _service_${1} ;;
  *) _service_help ;;
esac
