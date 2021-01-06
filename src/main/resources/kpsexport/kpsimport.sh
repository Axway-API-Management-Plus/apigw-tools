#!/bin/sh
set -euo pipefail

# Load common functions
CMD_NAME=$(basename $0)
CMD_HOME=$(dirname $0)
source ${CMD_HOME}/_common.sh

helpAndExit() {
  echo "${CMD_NAME} - import KPS tables to an API gateway instance"
  echo ""
  echo "Usage:"
  echo "  kpsimport -u USERNAME -p PASSWORD -g GROUP -n INSTANCE -f EXPORTARCHIVE [--no-backup]"
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
  echo "       archive (*.tgz) containing the exported KPS tables"
  echo "  --no-backup"
  echo "       suppress backup of target KPS"
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

      --no-backup)
        NO_BACKUP=1
        shift
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

NO_BACKUP=0

parseArgs $*
checkArgs
initCommand

#
# Check KPS archive
#
if [ ! -f "${EXPORT_TAR}" ]
then
  echo "ERROR: export archive not found: ${EXPORT_TAR}"
  exit 1
fi

EXPORT_UUID=$(tar -xzf ${EXPORT_TAR} --to-stdout uuid.txt)
echo "INFO : import KPS tables to group ${GROUP} and instance ${INSTANCE} using UUID ${EXPORT_UUID}"

#
# Save current KPS tables
#
if [ $NO_BACKUP -eq 0 ]
then
  echo "INFO : save current KPS tables"
  ARGS=("-u" "${USERNAME}" "-p" "${PASSWORD}" "-g" "${GROUP}" "-n" "${INSTANCE}" "backup")
  set +u # temp. disable variable check
  ${KPSADMIN} "${ARGS[@]}"
  if [ $? -ne 0 ]
  then
    echo "ERROR: creating backup failed"
    exit 1
  fi
  set -u # re-enable variable check
  unset ARGS
  echo "INFO : current KPS tables saved"
else
  echo "INFO : create backup is suppressed"
fi


#
# Extract KPS archive
#
tar -xzf "${EXPORT_TAR}" -C "${INSTANCE_BACKUP_DIR}"

#
# Restore KPS tables
#
echo "INFO : start kpsadmin clear"
ARGS=("-u" "${USERNAME}" "-p" "${PASSWORD}" "-g" "${GROUP}" "-n" "${INSTANCE}" "clear")
set +u # temp. disable variable check
${KPSADMIN} "${ARGS[@]}"
if [ $? -ne 0 ]
then
  echo "ERROR: clear failed"
  exit 1
fi
set -u # re-enable variable check
echo "INFO : kpsadmin clear succeeded"

echo "INFO : start kpsadmin restore"
ARGS=("-u" "${USERNAME}" "-p" "${PASSWORD}" "-g" "${GROUP}" "-n" "${INSTANCE}" "restore" "--uuid" "${EXPORT_UUID}")
set +u # temp. disable variable check
${KPSADMIN} "${ARGS[@]}"
if [ $? -ne 0 ]
then
  echo "ERROR: restore failed"
  exit 1
fi
set -u # re-enable variable check
unset ARGS
echo "INFO : kpsadmin restore succeeded"

echo "INFO : KPS tables import finished; please restart API Gateway instances"
