#!/bin/bash
 
set -e
 
SCRIPT_HOME=$(dirname "$0")
SCRIPT_HOME="`cd "${SCRIPT_HOME}" >/dev/null && pwd`"
SCRIPT_FOLDER="`basename $(dirname "$SCRIPT_HOME")`"
 
 
# ----- modify default settings -----
 
JS_RELEASE="2.5.0"
JS_REPOSITORY="sosberlin/js7"
JS_IMAGE="$(basename "${SCRIPT_HOME}")-${JS_RELEASE//\./-}"
 
JS_USER_ID="$(id -u)"
 
JS_HTTP_PORT="4445"
JS_HTTPS_PORT=
 
JS_JAVA_OPTIONS="-Xmx256m"
JS_BUILD_ARGS=
 
# ----- modify default settings -----
 
 
for option in "$@"
do
  case "$option" in
         --release=*)      JS_RELEASE=`echo "$option" | sed 's/--release=//'`
                           ;;
         --repository=*)   JS_REPOSITORY=`echo "$option" | sed 's/--repository=//'`
                           ;;
         --image=*)        JS_IMAGE=`echo "$option" | sed 's/--image=//'`
                           ;;
         --user-id=*)      JS_USER_ID=`echo "$option" | sed 's/--user-id=//'`
                           ;;
         --http-port=*)    JS_HTTP_PORT=`echo "$option" | sed 's/--http-port=//'`
                           ;;
         --https-port=*)   JS_HTTPS_PORT=`echo "$option" | sed 's/--https-port=//'`
                           ;;
         --java-options=*) JS_JAVA_OPTIONS=`echo "$option" | sed 's/--java-options=//'`
                           ;;
         --build-args=*)   JS_BUILD_ARGS=`echo "$option" | sed 's/--build-args=//'`
                           ;;
         *)                echo "unknown argument: $option"
                           exit 1
                           ;;
  esac
done
 
set -x
 
docker build --no-cache --rm \
      --tag=$JS_REPOSITORY:$JS_IMAGE \
      --file=$SCRIPT_HOME/build/Dockerfile \
      --build-arg="JS_RELEASE=$JS_RELEASE" \
      --build-arg="JS_RELEASE_MAJOR=$(echo $JS_RELEASE | cut -d . -f 1,2)" \
      --build-arg="JS_USER_ID=$JS_USER_ID" \
      --build-arg="JS_HTTP_PORT=$JS_HTTP_PORT" \
      --build-arg="JS_HTTPS_PORT=$JS_HTTPS_PORT" \
      --build-arg="JS_JAVA_OPTIONS=$JS_JAVA_OPTIONS" \
      $JS_BUILD_ARGS $SCRIPT_HOME/build
 
set +x