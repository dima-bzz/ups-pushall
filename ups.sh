#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CONF="${DIR}/ups.conf"
TEST="$1"
CACHE_STATUS=''

if ! which apcupsd &> /dev/null; then
  echo "apcupsd not installed"
  exit 1
fi

if [ ! -f "$CONF" ]; then
  echo "File configuration not found. Please copy ups.example.conf to ups.conf"
  exit 1
else
  # shellcheck disable=SC1090
  source "${CONF}"
fi

if [ -z "$TYPE" ] || [ -z "$ID" ] || [ -z "$KEY" ] || [ -z "$FILE" ]; then
  echo "The config file is configured incorrectly"
  exit 1
fi

if [ "$TYPE" = "multicast" ] && [ -z "$UIDS" ]; then
  echo "You are using multicast request type. UIDS must be set"
  exit 1
fi

if [ "$TYPE" = "unicast" ] && [ -z "$UIDD" ]; then
  echo "You are using unicast request type. UIDD must be set"
  exit 1
fi

if [ -n "$TEST" ]; then
  echo -e "Running test"
fi

push() {
  local -r status="$1"
  local -r bcharge="$2"
  local -r upsname="${3:-UPS}"

  # shellcheck disable=SC2153
  RTITLE="${TITLE//#upsname/$upsname}"
  # shellcheck disable=SC2153
  RTEXT=$(echo "${TEXT}" | sed "s/#status/${status}/; s/#bcharge/${bcharge}/; s/#upsname/${upsname}/;")

  if [ -z "$RTITLE" ]; then
    RTITLE="Status ${upsname}"
  fi

  if [ -z "$RTEXT" ]; then
    RTEXT="Status UPS: ${status} Battery Charge: ${bcharge}%"
  fi

  curl -sd "type=${TYPE}&id=${ID}&key=${KEY}&ttl=${TTL}&uid=${UIDD}&uids=${UIDS}&title=${RTITLE}&text=${RTEXT}" https://pushall.ru/api.php
}

check() {
  if [ -z "$TEST" ] && [ ! -f "$FILE" ]; then
    echo "File ${FILE} not found"
    exit 1
  fi

  if [ -z "$TEST" ]; then
    # shellcheck disable=SC2002
    UPSNAME=$(cat "${FILE}" | awk '/^(UPSNAME).*:/ {$1=$2="";print $0}' | sed -e 's/^[[:space:]]*//')
    # shellcheck disable=SC2002
    STATUS=$(cat "${FILE}" | awk '/^(STATUS).*:/ {print $3}')
    # shellcheck disable=SC2002
    BCHARGE=$(cat "${FILE}" | awk '/^(BCHARGE).*:/ {print $3}')
  else
    UPSNAME=""
    array=("ONLINE" "ONBATT")
    BCHARGE=$(( (RANDOM % 100 )  + 1 ))
    size="${#array[@]}"
    index=$((RANDOM % size))
    STATUS="${array[$index]}"
  fi

  if [ -z "$STATUS" ]; then
    echo "UPS Status not found"
    exit 1
  fi

  if [ "$CACHE_STATUS" != "$STATUS" ]; then
    if [ -z "$TEST" ]; then
      CACHE_STATUS="${STATUS}"
    fi
    push "${STATUS}" "${BCHARGE}" "${UPSNAME}"
  fi
}

while :
do
  check

  if [ -n "$TEST" ]; then
    echo -e
    exit 0
  fi

  sleep "${INTERVAL:-15}"
done
