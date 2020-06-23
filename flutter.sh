#!/usr/bin/env bash

SCRIPT_ABS=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_ABS")

# shellcheck disable=SC2005
DART_EXE=$(echo "$(command -v flutter)" | awk '{print substr($0,0,length()-7)}')cache/dart-sdk/bin/dart

if [[ ! -x "$DART_EXE" ]]; then
  echo "Can't find dart executable file !"
  return 1
fi


if [[ -f "./.hooks/pre_script.dart" ]]; then
  ${DART_EXE} ./.hooks/pre_script.dart "$@"
fi

if [[ -f "./pre_script.dart" ]]; then
  ${DART_EXE} ./.hooks/pre_script.dart "$@"
fi

if [[ -f "./.hooks/pre_script.sh" ]]; then
  ./.hooks/pre_script.sh "$@"
fi

if [[ -f "./pre_script.sh" ]]; then
  ./pre_script.sh "$@"
fi

${DART_EXE} "$SCRIPT_DIR"/bin/pre_script.dart "$@"

#flutter "$@"

${DART_EXE} "$SCRIPT_DIR"/bin/after_script.dart "$@"

if [[ -f "./.hooks/after_script.dart" ]]; then
  ${DART_EXE} ./.hooks/after_script.dart "$@"
fi

if [[ -f "./after_script.dart" ]]; then
  ${DART_EXE} ./after_script.dart "$@"
fi

if [[ -f "./.hooks/after_script.sh" ]]; then
  ./.hooks/after_script.sh "$@"
fi

if [[ -f "./after_script.sh" ]]; then
  ./after_script.sh "$@"
fi

