#!/bin/bash

JETTY_BASE="/var/sos-berlin.com/js7/joc"

update_joc_properties() {
  # update joc.properties file: ${JETTY_BASE}/resources/joc/joc.properties
  rc=$(grep -E '^cluster_id' "${JETTY_BASE}"/resources/joc/joc.properties)
  if [ -z "${rc}" ]
  then
    echo ".. update_joc_properties [INFO] updating cluster_id in ${JETTY_BASE}/resources/joc/joc.properties"
    printf "cluster_id = joc\n" >> "${JETTY_BASE}"/resources/joc/joc.properties
  fi

  rc=$(grep -E '^ordering' "${JETTY_BASE}"/resources/joc/joc.properties)
  if [ -z "${rc}" ]
  then
    echo ".. update_joc_properties [INFO] updating ordering in ${JETTY_BASE}/resources/joc/joc.properties"
    printf "ordering=%1\n" "$(shuf -i 0-99 -n 1)" >> "${JETTY_BASE}"/resources/joc/joc.properties
  fi
}

startini_to_startd() {
  # convert once ${JETTY_BASE}/resources/joc/start.ini to ${JETTY_BASE}/resources/joc/start.d
  if [ -d "${JETTY_BASE}"/start.d ]; then
    if [ -f "${JETTY_BASE}"/resources/joc/start.ini ] && [ -d "${JETTY_BASE}"/resources/joc/start.d ]; then
      echo ".. startini_to_startd [INFO] converting start.ini to start.d ini files"
      for file in "${JETTY_BASE}"/resources/joc/start.d/*.ini; do
        module="$(basename "$file" | cut -d. -f1)"
        echo ".... [INFO] processing module ${module}"
        while read -r line; do
          modulevariablekeyprefix="$(echo "${line}" | cut -d. -f1,2)"
          if [ "${modulevariablekeyprefix}" = "jetty.${module}" ] || [ "${modulevariablekeyprefix}" = "jetty.${module}Context" ]; then
            modulevariablekey="$(echo "${line}" | cut -d= -f1 | sed 's/\s*$//g')"
            echo "....  startini_to_startd [INFO] ${line}"
            sed -i "s;.*${modulevariablekey}\s*=.*;${line};g" "${file}"
          fi
        done < "${JETTY_BASE}"/resources/joc/start.ini
      done
      mv -f "${JETTY_BASE}"/resources/joc/start.ini "${JETTY_BASE}"/resources/joc/start.in~
    fi
  fi
}

add_start_configuration() {
  # overwrite ini files in start.d if available from config folder
  if [ -d "${JETTY_BASE}"/start.d ]; then
    if [ -d "${JETTY_BASE}"/resources/joc/start.d ]; then
      for file in "${JETTY_BASE}"/resources/joc/start.d/*.ini; do
        echo ".. add_start_configuration [INFO] copying ${file} -> ${JETTY_BASE}/start.d/"
        cp -f "$file" "${JETTY_BASE}"/start.d/
      done
    fi
  fi
}

add_jdbc_and_license() {
  # if license folder not empty then copy js7-license.jar to Jetty's class path
  if [ -d "${JETTY_BASE}"/resources/joc/license ]; then
    if [ -f "${JETTY_BASE}"/resources/joc/lib/js7-license.jar ]; then
      echo ".. add_jdbc_and_license [INFO] copying ${JETTY_BASE}/resources/joc/lib/js7-license.jar -> ${JETTY_BASE}/lib/ext/joc/"
      cp -f "${JETTY_BASE}"/resources/joc/lib/js7-license.jar "${JETTY_BASE}"/lib/ext/joc/
    fi
  fi

  # if JDBC driver added then copy to Jetty's class path and move exiting JDBC drivers back to avoid conflicts
  if [ -d "${JETTY_BASE}"/resources/joc/lib ]; then
    if [ -n "$(ls "${JETTY_BASE}"/resources/joc/lib/*.jar 2>/dev/null | grep -v "js7-license.jar")" ]; then
      for file in "${JETTY_BASE}"/lib/ext/joc/*.jar; do
        if [ "$(basename "$file")" != "js7-license.jar" ]; then
          echo ".. add_jdbc_and_license [INFO] moving ${file} -> ${JETTY_BASE}/resources/joc/lib/$(basename "$file")~"
          mv -f "$file" "${JETTY_BASE}"/resources/joc/lib/"$(basename "$file")"~
        fi
      done

      for file in "${JETTY_BASE}"/resources/joc/lib/*.jar; do
        echo ".. add_jdbc_and_license [INFO] copying ${file} -> ${JETTY_BASE}/lib/ext/joc/"
        cp -f "$file" "${JETTY_BASE}"/lib/ext/joc/
      done
    fi
  fi
}

add_custom_logo() {
  # if image folder in the configuration directory is not empty then images are copied to the installation directory
  if [ -d "${JETTY_BASE}"/resources/joc/image ];then
    mkdir -p  "${JETTY_BASE}"/webapps/root/ext/images
    echo ".. add_custom_logo [INFO] copying ${JETTY_BASE}/resources/joc/image/* -> ${JETTY_BASE}/webapps/root/ext/images/"
    cp "${JETTY_BASE}"/resources/joc/image/* "${JETTY_BASE}"/webapps/root/ext/images/
  fi
}

patch_api() {
  if [ ! -d "${JETTY_BASE}"/resources/joc/patches ]; then
    echo ".. patch_api [INFO] API patch directory not found: ${JETTY_BASE}/resources/joc/patches"
    return
  fi

  if [ ! -d "${JETTY_BASE}"/webapps/joc/WEB-INF/classes ]; then
    echo ".. patch_api [WARN] JOC Cockpit API sub-directory not found: ${JETTY_BASE}/webapps/joc/WEB-INF/classes" 
    return
  fi

  jarfiles=$(ls "${JETTY_BASE}"/resources/joc/patches/js7_joc.*-PATCH.API-*.jar 2>/dev/null)
  if [ -n "${jarfiles}" ]; then
    cd "${JETTY_BASE}"/webapps/joc/WEB-INF/classes > /dev/null || return
    for jarfile in "${JETTY_BASE}"/resources/joc/patches/js7_joc.*-PATCH.API-*.jar; do
      echo ".. patch_api [INFO] extracting ${jarfile} -> ${JETTY_BASE}/webapps/joc/WEB-INF/classes"
      unzip -o "${jarfile}" || return
      # rm -f "${jarfile}" || return
    done
    cd - > /dev/null || return
  else
    echo ".. patch_api [INFO] no API patches available from .jar files in directory: ${JETTY_BASE}/resources/joc/patches"
  fi

  tarballs=$(ls "${JETTY_BASE}"/resources/joc/patches/js7_joc.*-PATCH.API-*.tar.gz 2>/dev/null)
  if [ -n "${tarballs}" ]; then
    if [ "$(echo "${tarball}" | wc -l)" -eq 1 ]; then
      cd "${JETTY_BASE}"/webapps/joc/WEB-INF/classes > /dev/null || return
      for tarfile in "${JETTY_BASE}"/resources/joc/patches/js7_joc.*-PATCH.API-*.tar.gz; do
        echo ".. patch_api [INFO] extracting ${tarfile} -> ${JETTY_BASE}/webapps/joc/WEB-INF/classes"
        tar -xpozf "${tarfile}" || return
        # rm -f  "${tarfile}" || return

        for jarfile in "${JETTY_BASE}"/resources/joc/patches/js7_joc.*-PATCH.API-*.jar; do
          echo ".. patch_api [INFO] extracting ${jarfile} -> ${JETTY_BASE}/webapps/joc/WEB-INF/classes"
          unzip -o "${jarfile}"
          # rm -f  "${jarfile}" || return
        done

        # rm -f "${tarfile}" || return
      done
      cd - > /dev/null || return
    else
      echo ".. patch_api [WARN]: more than one tarball found for API patches. Please drop previous patch tarballs and use the latest API patch tarball only as it includes previous patches."
    fi
  else
     echo ".. patch_api [INFO] no API patches available from .tar.gz files in directory: ${JETTY_BASE}/resources/joc/patches"
  fi
}

patch_gui() {
  if [ ! -d "${JETTY_BASE}"/resources/joc/patches ]; then
    echo ".. patch_gui [INFO] GUI patch directory not found: ${JETTY_BASE}/resources/joc/patches"
    return
  fi

  if [ ! -d "${JETTY_BASE}"/webapps/joc ]; then
    echo ".. patch_gui [WARN] JOC Cockpit GUI sub-directory not found: ${JETTY_BASE}/webapps/joc"
    return
  fi

  tarball=$(ls "${JETTY_BASE}"/resources/joc/patches/js7_joc.*-PATCH.GUI-*.tar.gz 2>/dev/null)
  if [ -n "${tarball}" ]; then
    if [ "$(echo "${tarball}" | wc -l)" -eq 1 ]; then
      echo ".. patch_gui [INFO] applying GUI patch tarball: ${tarball}"
      cd "${JETTY_BASE}"/webapps/joc > /dev/null || return
      find "${JETTY_BASE}"/webapps/joc -maxdepth 1 -type f -delete || return

      if [ -d "${JETTY_BASE}"/webapps/joc/assets ]; then
        rm -fr "${JETTY_BASE}"/webapps/joc/assets || return
      fi

      if [ -d "${JETTY_BASE}"/webapps/joc/styles ]; then
        rm -fr "${JETTY_BASE}"/webapps/joc/styles || return
      fi

      tar -xpozf "${tarball}" || return
      cd - > /dev/null || return
    else
      echo ".. patch_gui [WARN]: more than one tarball found for GUI patches. Please drop previous patch tarballs and use the latest GUI patch tarball only as it includes previous patches."
    fi
  else
    echo ".. patch_gui [INFO] no GUI patches available from .tar.gz files in directory: ${JETTY_BASE}/resources/joc/patches"
  fi
}


# create JOC Cockpit start script
echo '#!/bin/sh' > "${JETTY_BASE}"/start-joc.sh
echo 'trap "/opt/sos-berlin.com/js7/joc/jetty/bin/jetty.sh stop; exit" TERM INT' >> "${JETTY_BASE}"/start-joc.sh
echo '/opt/sos-berlin.com/js7/joc/jetty/bin/jetty.sh start && tail -f /dev/null &'   >> "${JETTY_BASE}"/start-joc.sh
echo 'wait' >> "${JETTY_BASE}"/start-joc.sh
chmod +x "${JETTY_BASE}"/start-joc.sh

echo "JS7 entrypoint script: updating image"

# update joc.properties file
update_joc_properties

# start.ini_to_startd
add_start_configuration

# copy custom logo
add_custom_logo


if [ -n "${RUN_JS_HTTP_PORT}" ]
then
  if [ -f "${JETTY_BASE}"/start.d/http.in~ ] && [ ! -f "${JETTY_BASE}"/start.d/http.ini ]; then
    # enable http access in start.d directory
    mv "${JETTY_BASE}"/start.d/http.in~ "${JETTY_BASE}"/start.d/http.ini
  fi
  if [ -f "${JETTY_BASE}"/start.d/http.ini ]; then
    # set port for http access in start.d directory
    sed -i "s/.*jetty.http.port\s*=.*/jetty.http.port=$RUN_JS_HTTP_PORT/g" "${JETTY_BASE}"/start.d/http.ini
  fi
else
  if [ -f "${JETTY_BASE}"/start.d/http.ini ]; then
    # disable http access in start.d directory
    mv -f "${JETTY_BASE}"/start.d/http.ini "${JETTY_BASE}"/start.d/http.in~
  fi
fi

if [ -n "${RUN_JS_HTTPS_PORT}" ]
then
  if [ -f "${JETTY_BASE}"/start.d/https.in~ ] && [ ! -f "${JETTY_BASE}"/start.d/https.ini ]; then
    # enable https access in start.d directory
    mv "${JETTY_BASE}"/start.d/https.in~ "${JETTY_BASE}"/start.d/https.ini
  fi
  if [ -f "${JETTY_BASE}"/start.d/ssl.in~ ] && [ ! -f "${JETTY_BASE}"/start.d/ssl.ini ]; then
    # enable https access in start.d directory
    mv "${JETTY_BASE}"/start.d/ssl.in~ "${JETTY_BASE}"/start.d/ssl.ini
  fi
  if [ -f "${JETTY_BASE}"/start.d/ssl.ini ]; then
    # set port for https access in start.d directory
    sed -i "s/.*jetty.ssl.port\s*=.*/jetty.ssl.port=${RUN_JS_HTTPS_PORT}/g" "${JETTY_BASE}"/start.d/ssl.ini
  fi
else
  if [ -f "${JETTY_BASE}"/start.d/https.ini ]; then
    # disable https access in start.d directory
    mv -f "${JETTY_BASE}"/start.d/https.ini "${JETTY_BASE}"/start.d/https.in~
  fi
  if [ -f "${JETTY_BASE}"/start.d/ssl.ini ]; then
    # disable https access in start.d directory
    mv -f "${JETTY_BASE}"/start.d/ssl.ini "${JETTY_BASE}"/start.d/ssl.in~
  fi
fi

if [ -n "${RUN_JS_JAVA_OPTIONS}" ]
then
  export JAVA_OPTIONS="${JAVA_OPTIONS} ${RUN_JS_JAVA_OPTIONS}"
fi

JS_USER_ID=$(echo "${RUN_JS_USER_ID}" | cut -d ':' -f 1)
JS_GROUP_ID=$(echo "${RUN_JS_USER_ID}" | cut -d ':' -f 2)

JS_USER_ID=${JS_USER_ID:-$(id -u)}
JS_GROUP_ID=${JS_GROUP_ID:-$(id -g)}

BUILD_GROUP_ID=$(grep 'jobscheduler' /etc/group | head -1 | cut -d ':' -f 3)
BUILD_USER_ID=$(grep 'jobscheduler' /etc/passwd | head -1 | cut -d ':' -f 3)

add_jdbc_and_license
patch_api
patch_gui

if [ "$(id -u)" = "0" ]
then
  if [ ! "${BUILD_USER_ID}" = "${JS_USER_ID}" ]
  then
    echo "JS7 entrypoint script: switching ownership of image user id '${BUILD_USER_ID}' -> '${JS_USER_ID}'"
    usermod -u "${JS_USER_ID}" jobscheduler
    find /var/sos-berlin.com/ -user "${BUILD_USER_ID}" -exec chown -h jobscheduler {} \;
    find /var/log/sos-berlin.com/ -user "${BUILD_USER_ID}" -exec chown -h jobscheduler {} \;
  fi

  if [ ! "${BUILD_GROUP_ID}" = "${JS_GROUP_ID}" ]
  then
    if grep -q "${JS_GROUP_ID}" /etc/group
    then
      groupmod -g "${JS_GROUP_ID}" jobscheduler
    else
      addgroup -g "${JS_GROUP_ID}" -S jobscheduler
    fi

    echo "JS7 entrypoint script: switching ownership of image group id '${BUILD_GROUP_ID}' -> '${JS_GROUP_ID}'"
    find /var/sos-berlin.com/ -group "${BUILD_GROUP_ID}" -exec chgrp -h jobscheduler {} \;
    find /var/log/sos-berlin.com/ -group "${BUILD_GROUP_ID}" -exec chgrp -h jobscheduler {} \;
  fi

  echo "JS7 entrypoint script: switching to user account 'jobscheduler' to run start script"
  echo "JS7 entrypoint script: starting JOC Cockpit: exec su-exec ${JS_USER_ID}:${JS_GROUP_ID} /opt/sos-berlin.com/js7/joc/jetty/bin/jetty.sh start"
  exec su-exec "${JS_USER_ID}":0 "${JETTY_BASE}"/start-joc.sh
else
  if [ "${BUILD_USER_ID}" = "${JS_USER_ID}" ]
  then
    if [ "$(id -u)" = "${JS_USER_ID}" ]
    then
      echo "JS7 entrypoint script: running for user id '$(id -u)'"
    else
      echo "JS7 entrypoint script: running for user id '$(id -u)' using user id '${JS_USER_ID}', group id '${JS_GROUP_ID}'"
      echo "JS7 entrypoint script: missing permission to switch user id and group id, consider to omit the 'docker run --user' option"
    fi
  else
    echo "JS7 entrypoint script: running for user id '$(id -u)', image user id '${BUILD_USER_ID}' -> '${JS_USER_ID}', image group id '${BUILD_GROUP_ID}' -> '${JS_GROUP_ID}'"
  fi

  echo "JS7 entrypoint script: starting JOC Cockpit: exec sh -c /opt/sos-berlin.com/js7/joc/jetty/bin/jetty.sh start"
  exec sh -c "${JETTY_BASE}/start-joc.sh"
fi

