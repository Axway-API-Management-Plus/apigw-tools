######################################################################
# Common variables and functions for kpsexport and kpsimport

initCommand() {
  # check Axway home directory
  if [ "" == "${AXWAY_HOME:-}" ]
  then
    echo "ERROR: AXWAY_HOME not defined"
    exit 1
  fi
  if [ ! -d ${AXWAY_HOME}/apigateway ]
  then
    echo "ERROR: invalid Axway home directory; missing 'apigateway' subfolder: ${AXWAY_HOME}"
    exit 1
  fi

  # kpsadmin command
  KPSADMIN=${AXWAY_HOME}/apigateway/posix/bin/kpsadmin
  if [ ! -x ${KPSADMIN} ]
  then
    echo "ERROR: kpsadmin not found or not executable: ${KPSADMIN}"
    exit 1
  fi 

  # instance directory  
  INSTANCE_DIR="${AXWAY_HOME}/apigateway/groups/topologylinks/${GROUP}-${INSTANCE}"
  INSTANCE_BACKUP_DIR=${INSTANCE_DIR}/conf/kps/backup
  
  if [ ! -d ${INSTANCE_DIR} ]
  then
    echo "ERROR: no instance directory: ${INSTANCE_DIR}"
    exit 1
  fi
}
