#!/usr/bin/env bash

# The following provides an improvement upon
# https://github.com/vishnubob/wait-for-it by also allowing to require
# that the URL leads a particular BODY. Perhaps, such an improvement
# should be pushed upstream. For now, this script is self-contained.

set -euo pipefail

default_timeout=30
default_n_attempts=4

timeout=$default_timeout
n_attempts=$default_n_attempts
args=
body=
require_body=0 # false

called_as=$0

show_help() {
  printf \
"Usage: ${called_as} [OPTION...] URL

Wait for cURL to succeed with given URL.

  -n, --n_attempts N      maximum number of attempts to perform (default: ${default_n_attempts})
  -t, --timeout N_SECS    number of seconds to wait between attempts (default: ${default_timeout})
  -a, --args TEXT         the arguments to provide to cURL (default: \"\")
  -b, --body TEXT         the body to wait for (default: body is ignored)
"
}

if [ $# -lt 1 ]
then
  show_help
  exit 1
fi

while true
do
  case "$1" in
    -t|--timeout)
      timeout=$2
      shift 2
      ;;
    -n|--n_attempts)
      n_attempts=$2
      shift 2
      ;;
    -a|--args)
      args=$2
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      shift 1
      ;;
    -b|--body)
      body=$2
      require_body=1 # true
      shift 2
      ;;
    -*)
      show_help
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

url=$1

attempt=0
until [[ ${attempt} -eq ${n_attempts} ]]
do
  attempt=$((attempt+1))
  printf "Attempt %d/%d: " "${attempt}" "${n_attempts}"

  set +e
  response="$(curl --silent ${args} "${url}")"
  code=$?
  set -e
  if [ $code -eq 0 ]
  then
    if [ ${require_body} -eq 0 ] || [ "${response}" == "${body}" ]
    then
      printf "Success!\n"
      exit 0
    else
      printf "${url} is responding, but not with the expected body.\n"
      printf "Current response:\n${response}\n\n"
    fi
  else
    printf "${url} is not yet responding..\n"
  fi
  printf "Waiting %d seconds before attempting one more time..\n" \
    "${timeout}"
  sleep "${timeout}s"
done

printf "${url} did not respond properly after %d attempts.\n" "${n_attempts}" >&2
exit 1
