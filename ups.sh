#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CONF="${DIR}/ups.conf"
TEST="$1"
CACHE_STATUS=''

log() {
  local -r type="$1"
  shift

  echo -e "$(date) [${type}]: $*"
}

push() {
  local -r status="$1"
  local -r bcharge="$2"
  local -r upsname="${3:-UPS}"
  local -r timeleft="$4"

  # shellcheck disable=SC2153
  RTITLE="${TITLE//#upsname/$upsname}"
  # shellcheck disable=SC2153
  RTEXT=$(echo "${TEXT}" | sed "s/#status/${status}/; s/#bcharge/${bcharge}/; s/#upsname/${upsname}/; s/#timeleft/${timeleft}/;")

  if [ -z "$RTITLE" ]; then
    RTITLE="Status ${upsname}"
  fi

  if [ -z "$RTEXT" ]; then
    RTEXT="Status UPS: ${status} Battery Charge: ${bcharge}% Time Left: ${timeleft}"
  fi

  RUN=$(curl -sd "type=${TYPE}&id=${ID}&key=${KEY}&ttl=${TTL}&uid=${UIDD}&uids=${UIDS}&title=${RTITLE}&text=${RTEXT}" https://pushall.ru/api.php)
  log "INFO" "Message sending result: ${RUN}"
}

check() {
  if [ -z "$TEST" ]; then
    # shellcheck disable=SC2002
    UPSNAME=$(cat "${FILE}" | awk '/^(UPSNAME).*:/ {$1=$2="";print $0}' | sed -e 's/^[[:space:]]*//')
    # shellcheck disable=SC2002
    STATUS=$(cat "${FILE}" | awk '/^(STATUS).*:/ {print $3}')
    # shellcheck disable=SC2002
    BCHARGE=$(cat "${FILE}" | awk '/^(BCHARGE).*:/ {print $3}' | bc)
    # shellcheck disable=SC2002
    TIMELEFT=$(cat "${FILE}" | awk '/^(TIMELEFT).*:/ {$1=$2="";print $0}' | sed -e 's/^[[:space:]]*//')
  else
    UPSNAME=""
    array=("ONLINE" "ONBATT")
    BCHARGE=$(( (RANDOM % 100 )  + 1 ))
    TIMELEFT=$(( (RANDOM % 100 )  + 1 ))
    TIMELEFT="${TIMELEFT} Minutes"
    size="${#array[@]}"
    index=$((RANDOM % size))
    STATUS="${array[$index]}"
  fi

  if [ -z "$STATUS" ]; then
    log "WARNING" "UPS Status not found in ${FILE}"
    return
  fi

  if [ "$CACHE_STATUS" != "$STATUS" ]; then
    if [ -z "$TEST" ]; then
      CACHE_STATUS="${STATUS}"
    fi
    push "${STATUS}" "${BCHARGE}" "${UPSNAME}" "${TIMELEFT}"
  else
    if [ -n "$TEST" ]; then
      log "INFO" "Skipped"
    fi
  fi
}

if ! which apcupsd &> /dev/null; then
  log "ERROR" "apcupsd not installed"
  exit 1
fi

if [ ! -f "$CONF" ]; then
  log "ERROR" "File configuration not found. Please copy ups.example.conf to ups.conf"
  exit 1
else
  # shellcheck disable=SC1090
  source "${CONF}"
fi

if [ -z "$TYPE" ] || [ -z "$ID" ] || [ -z "$KEY" ] || [ -z "$FILE" ]; then
  log "ERROR" "The config file is configured incorrectly"
  exit 1
fi

if [ -z "$TEST" ] && [ ! -f "$FILE" ]; then
  log "ERROR" "File ${FILE} not found"
  exit 1
fi

if [ "$TYPE" = "multicast" ] && [ -z "$UIDS" ]; then
  log "ERROR" "You are using multicast request type. UIDS must be set"
  exit 1
elif [ "$TYPE" = "unicast" ] && [ -z "$UIDD" ]; then
  log "ERROR" "You are using unicast request type. UIDD must be set"
  exit 1
fi

log "INFO" "Service started successfully"

while :
do
  check

  if [ -n "$TEST" ]; then
    exit 0
  fi

  if [ "$CACHE_STATUS" = "ONBATT" ] && [ "$BATT_INTERVAL" -gt 0 ]; then
    CACHE_STATUS=""
    sleep "${BATT_INTERVAL}"
  else
    sleep "${INTERVAL:-15}"
  fi

done
