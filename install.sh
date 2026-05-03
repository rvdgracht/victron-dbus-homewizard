#!/bin/sh

ARGS="$@"
THISDIR="$(cd $(dirname "$0") && pwd)"

# Get the service name from the supplied arguments
LAST_POSITIONAL_ARG=""
while [ $# -gt 0 ]; do
  case $1 in
    -*|--*)
      shift                     # Ignore all optional args
      ;;
    *)
      LAST_POSITIONAL_ARG="$1"  # Save positional argument
      ;;
    esac
    shift
done
if [ -z "${LAST_POSITIONAL_ARG}" ]; then
    >&2 echo "ERROR: Supply the arguments as used with run.sh to this script"
    exit 1
fi
SERVICE_NAME="dbus-homewizard-${LAST_POSITIONAL_ARG}"


# Check for a previous install with the same name
SERVICE_PATH="/service/${SERVICE_NAME}"
if [ -e "${SERVICE_PATH}" ]; then
    >&2 echo "Service path ${SERVICE_PATH} already exists. Remove it to continue."
    exit 2
fi
SERVICE_DIR="${THISDIR}/service/${SERVICE_NAME}"
if [ -d "${SERVICE_DIR}" ]; then
    >&2 echo "Service output dir '$(dirname $0)/service/${SERVICE_NAME}' already exists. Remove it to continue."
    exit 3
fi

# Build the service dir in this dir
echo "Creating service dir '${SERVICE_DIR}'"
mkdir -p "${SERVICE_DIR}"
echo "#!/bin/sh" > "${SERVICE_DIR}/run"
echo "exec ${THISDIR}/run.sh ${ARGS} 2>&1" >> "${SERVICE_DIR}/run"
chmod +x "${SERVICE_DIR}/run"

RC_LOCAL=/data/rc.local
# Check if rc.local exists
if [ ! -x "${RC_LOCAL}" ]; then
    echo "Creating executable file '${RC_LOCAL}'"
    echo "#!/bin/sh" > "${RC_LOCAL}"
    chmod +x "${RC_LOCAL}"
fi

# Add a line to rc.local to (auto)start the serivce at boot
grep -q "${SERVICE_PATH}" $RC_LOCAL
if [ $? != 0 ]; then
    # No entry for a service with this name in the rc.local, lets add it
    echo "Adding line to '${RC_LOCAL}' to autostart this service at boot"
    echo "ln -s ${SERVICE_DIR} ${SERVICE_PATH}" >> "${RC_LOCAL}"
fi

echo "Starting the new service right away"
ln -sf "${SERVICE_DIR}" "${SERVICE_PATH}"

echo "Service is now installed and started in the background"
