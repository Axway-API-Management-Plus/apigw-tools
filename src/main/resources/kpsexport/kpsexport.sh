#!/bin/sh
set -euo pipefail

# Load common functions
CMD_NAME=$(basename $0)
CMD_HOME=$(dirname $0)
source ${CMD_HOME}/_common.sh

helpAndExit() {
  echo "${CMD_NAME} - export KPS tables of an API gateway instance"
  echo ""
  echo "Usage:"
  echo "  kpsexport -u USERNAME -p PASSWORD -g GROUP -n INSTANCE -f EXPORTARCHIVE"
  echo ""
  echo "Options:"
  echo "  -u USERNAME"
  echo "       Node Manager username."
  echo "  -p PASSWORD"
  echo "       Node Manager password."
  echo "  -g GROUP"
  echo "       API Gateway group"
  echo "  -n INSTANCE"
  echo "       API Gateway instance"
  echo "  -f EXPORTARCHIVE"
  echo "       archive (*.tgz) for exported KPS tables"
  echo ""
  exit 1
}

parseArgs() {
  while [[ $# -gt 0 ]]
  do
    option="$1"

    case $option in
      -u)
        if [[ $# -gt 1 ]]
        then
          USERNAME="$2"
          shift
          shift
        else
          echo "ERROR: missing user name"
          exit 1
        fi
        ;;
      -p)
        if [[ $# -gt 1 ]]
        then
          PASSWORD="$2"
          shift
          shift
        else
          echo "ERROR: missing password"
          exit 1
        fi
        ;;
      -g)
        if [[ $# -gt 1 ]]
        then
          GROUP="$2"
          shift
          shift
        else
          echo "ERROR: missing group"
          exit 1
        fi
        ;;
      -n)
        if [[ $# -gt 1 ]]
        then
          INSTANCE="$2"
          shift
          shift
        else
          echo "ERROR: missing instance"
          exit 1
        fi
        ;;
      -f)
        if [[ $# -gt 1 ]]
        then
          EXPORT_TAR="$2"
          shift
          shift
        else
          echo "ERROR: missing export archive"
          exit 1
        fi
        ;;
      *)
        echo "ERROR: unknown option $1"
        exit 1
        ;;
    esac
  done
}

checkArgs() {
  if [ -z "${USERNAME:-}" ]
  then
    echo "ERROR: missing -u option"
    exit 1
  fi
  if [ -z "${PASSWORD:-}" ]
  then
    echo "ERROR: missing -p option"
    exit 1
  fi
  if [ -z "${GROUP:-}" ]
  then
    echo "ERROR: missing -g option"
    exit 1
  fi
  if [ -z "${INSTANCE:-}" ]
  then
    echo "ERROR: missing -n option"
    exit 1
  fi
  if [ -z "${EXPORT_TAR:-}" ]
  then
    echo "ERROR: missing -f option"
    exit 1
  fi
}

#
# Parse command line arguments
#
if [ $# -lt 1 ]
then
  helpAndExit
fi

parseArgs $*
checkArgs
initCommand

#
# Execute kpsadmin to export KPS tables
#
EXPORT_TAR=$(realpath $EXPORT_TAR)
EXPORT_LOG="${EXPORT_TAR}.log"

echo "INFO : export KPS tables of group ${GROUP} from instance ${INSTANCE}"
echo "INFO : export archive '${EXPORT_TAR}'"
echo "INFO : start kpsadmin backup"

ARGS=("-u" "${USERNAME}" "-p" "${PASSWORD}" "-g" "${GROUP}" "-n" "${INSTANCE}" "backup")
set +u # temp. disable variable check
${KPSADMIN} "${ARGS[@]}" | tee "${EXPORT_LOG}"
if [ $? -ne 0 ]
then
  echo "ERROR: kpsadmin failed"
  exit 1
fi
set -u # re-enable variable check
unset ARGS
echo "INFO : kpsadmin backup finished"

#
# Create KPS archive
#
EXPORT_UUID=$(grep "Backup uuid is: " ${EXPORT_LOG} | cut -d ":" -f 2 | tr -d '[:space:]')
echo "INFO : create archive for UUID ${EXPORT_UUID}"

FILE_PREFIX=$(echo "$EXPORT_UUID" | tr "-" "_")
FILE_PATTERN="${FILE_PREFIX}_*"

pushd "${INSTANCE_BACKUP_DIR}" > /dev/null
echo ${EXPORT_UUID} > "uuid.txt"
tar -czf "${EXPORT_TAR}" uuid.txt ${FILE_PATTERN}
if [ $? -ne 0 ]
then
  echo "ERROR: creating export archive failed: ${EXPORT_TAR}"
  popd > /dev/null
  exit 1
fi
popd > /dev/null

echo "INFO : export archive created ${EXPORT_TAR}"
