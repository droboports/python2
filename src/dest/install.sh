#!/usr/bin/env sh

prog_dir="$(dirname "$(realpath "${0}")")"
name="$(basename "${prog_dir}")"
tmp_dir="/tmp/DroboApps/${name}"
logfile="${tmp_dir}/install.log"

# boilerplate
if [ ! -d "${tmp_dir}" ]; then mkdir -p "${tmp_dir}"; fi
exec 3>&1 4>&2 1>> "${logfile}" 2>&1
echo "$(date +"%Y-%m-%d %H-%M-%S"):" "${0}" "${@}"
set -o errexit  # exit on uncaught error code
set -o nounset  # exit on unset variable
set -o pipefail # propagate last error code on pipe
set -o xtrace   # enable script tracing

# copy default configuration files
find "${prog_dir}" -type f -name "*.default" -print | while read deffile; do
  basefile="$(dirname "${deffile}")/$(basename "${deffile}" .default)"
  if [ ! -f "${basefile}" ]; then
    cp -vf "${deffile}" "${basefile}"
  fi
done

# symlink /usr/bin/python
if [ ! -e "/usr/bin/python" ]; then
  ln -s "${prog_dir}/bin/python2.7" "/usr/bin/python"
elif [ -h "/usr/bin/python" ] && [ "$(readlink /usr/bin/python)" != "${prog_dir}/bin/python2.7" ]; then
  ln -fs "${prog_dir}/bin/python2.7" "/usr/bin/python"
fi
