#!/bin/bash

main() {
  echo "" # see https://github.com/actions/toolkit/issues/168

  if usesBoolean "${ACTIONS_STEP_DEBUG}"; then
    echo "::add-mask::${INPUT_HOST}"
    echo "::add-mask::${INPUT_USERNAME}"
    echo "::add-mask::${INPUT_KEY}"
    echo "::add-output::${INPUT_TARGET}"
    echo "::add-output::${INPUT_FILES}"
    echo "::add-output::${INPUT_RECURSIVE}"
  fi

  # make sure remote folder exists
  CMDS="-mkdir \"${INPUT_TARGET}\"\n"
  FOLDER=$(dirname $INPUT_TARGET)
  OLDFOLDER="${INPUT_TARGET}"
  while [ "${FOLDER}" != "." -a "${FOLDER}" != "/" -a "${FOLDER}" != "${OLDFOLDER}" ]; do
    CMDS="-mkdir \"${FOLDER}\"\n${CMDS}"
    OLDFOLDER="${FOLDER}"
    FOLDER=$(dirname ${FOLDER})
  done

  # copy the files
  for x in ${INPUT_FILES}; do
  	if [ -d "${x}" ]; then
      CMDS="${CMDS}\nput -pR \"${x}\" \"${INPUT_TARGET}\"\n"
    elif [ -e "${x}" ]; then
      CMDS="${CMDS}\nput -p \"${x}\" \"${INPUT_TARGET}\"\n"
    else
      echo "Could not find file ${x}"
      exit 1
    fi
  done

  # done
  CMDS="${CMDS}\nbye\n"

  # save script
  echo -e "${CMDS}" > batchjob
  if usesBoolean "${ACTIONS_STEP_DEBUG}"; then
    echo "::add-output::${CMDS}"
  fi

  # save key
  echo -e "${INPUT_KEY}" > sshkey
  chmod 600 sshkey

  # check options
  OPTS="-o StrictHostKeyChecking=no"
  if usesBoolean "${ACTIONS_STEP_DEBUG}"; then
  	OPTS="${OPTS} -v"
  fi

  # copy files
  sftp ${OPTS} -p -i sshkey -b batchjob ${INPUT_USERNAME}@${INPUT_HOST}
}

usesBoolean() {
  [ ! -z "${1}" ] && [ "${1}" = "true" ]
}

main
