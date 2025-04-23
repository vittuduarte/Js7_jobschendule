#!/bin/bash

js_args=()
js_args_count=0

if [ -n "${RUN_JS_ID}" ]
then
  js_args["${js_args_count}"]="--id=${RUN_JS_ID}"
  js_args_count=$(( "${js_args_count}" + 1 ))
fi

if [ -n "${RUN_JS_HTTP_PORT}" ] && [ ! "${RUN_JS_HTTP_PORT}" = ":" ]
then
  js_args["${js_args_count}"]="--http-port=${RUN_JS_HTTP_PORT}"
  js_args_count=$(( "${js_args_count}" + 1 ))
fi

if [ -n "${RUN_JS_HTTPS_PORT}" ] && [ ! "${RUN_JS_HTTPS_PORT}" = ":" ]
then
  js_args["${js_args_count}"]="--https-port=${RUN_JS_HTTPS_PORT}"
  js_args_count=$(( "${js_args_count}" + 1 ))
fi

if [ -n "${RUN_JS_JAVA_OPTIONS}" ]
then
  js_args["${js_args_count}"]="--java-options=\"${RUN_JS_JAVA_OPTIONS}\""
  js_args_count=$(( "${js_args_count}" + 1 ))
fi

# work directory will be created by container
if [ -d "/var/sos-berlin.com/js7/controller/work" ] && [ -w "/var/sos-berlin.com/js7/controller/work" ]
then
  rm -f -r /var/sos-berlin.com/js7/controller/work
fi

JS_USER_ID=$(echo "${RUN_JS_USER_ID}" | cut -d ':' -f 1)
JS_GROUP_ID=$(echo "${RUN_JS_USER_ID}" | cut -d ':' -f 2)

JS_USER_ID=${JS_USER_ID:-$(id -u)}
JS_GROUP_ID=${JS_GROUP_ID:-$(id -g)}

BUILD_GROUP_ID=$(cat /etc/group | grep jobscheduler | cut -d ':' -f 3)
BUILD_USER_ID=$(cat /etc/passwd | grep jobscheduler | cut -d ':' -f 4)

if [ "$(id -u)" = "0" ]
then
  if [ ! "{$BUILD_USER_ID}" = "${JS_USER_ID}" ]
  then
    echo "JS7 entrypoint script switching ownership of image user id '${BUILD_USER_ID}' -> '${JS_USER_ID}'"
    usermod -u "${JS_USER_ID}" jobscheduler
    find /var/sos-berlin.com/ -user "${BUILD_USER_ID}" -exec chown -h jobscheduler {} \;
  fi
  
  if [ ! "${BUILD_GROUP_ID}" = "${JS_GROUP_ID}" ]
  then
    if grep -q "${JS_GROUP_ID}" /etc/group
    then
      groupmod -g "${JS_GROUP_ID}" jobscheduler
    else
      addgroup -g ${JS_GROUP_ID} -S jobscheduler
    fi

    echo "JS7 entrypoint script switchng ownership of image group id '${BUILD_GROUP_ID}' -> '${JS_GROUP_ID}'"
    find /var/sos-berlin.com/ -group "${BUILD_GROUP_ID}" -exec chgrp -h jobscheduler {} \;
  fi

  echo "JS7 entrypoint script switching to user account 'jobscheduler' to run start script"
  echo "JS7 entrypoint script starting Controller: exec su-exec ${JS_USER_ID}:${JS_GROUP_ID} /opt/sos-berlin.com/js7/controller/bin/controller_instance.sh start-docker" "${js_args[@]}"
  exec su-exec "${JS_USER_ID}":"${JS_GROUP_ID}" /opt/sos-berlin.com/js7/controller/bin/controller_instance.sh start-docker "${js_args[@]}"
else
  if [ "${BUILD_USER_ID}" = "${JS_USER_ID}" ]
  then
    if [ "$(id -u)" = "${JS_USER_ID}" ]
    then
      echo "JS7 entrypoint script running for user id '$(id -u)'"
    else
      echo "JS7 entrypoint script running for user id '$(id -u)' using user id '${JS_USER_ID}', group id '${JS_GROUP_ID}'"
      echo "JS7 entrypoint script missing permission to switch user id and group id, consider to omit the 'docker run --user' option"
    fi
  else
    echo "JS7 entrypoint script running for user id '$(id -u)' using image user id '${BUILD_USER_ID}' -> '${JS_USER_ID}', image group id '${BUILD_GROUP_ID}' -> '${JS_GROUP_ID}'"
  fi

  echo "JS7 entrypoint script starting Controller: exec sh -c /opt/sos-berlin.com/js7/controller/bin/controller_instance.sh start-docker ${js_args[*]}"
  exec sh -c "/opt/sos-berlin.com/js7/controller/bin/controller_instance.sh start-docker ${js_args[*]}"
fi

