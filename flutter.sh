#!/usr/bin/env bash

SCRIPT_ABS=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_ABS")

# shellcheck disable=SC2005
DART_EXE=$(command -v dart)

JUST_REPLACE=0
for i in "$@"
do
   [ "$i" == "--replace" ] && JUST_REPLACE=1
done

echo Original args is : [ "$@" ]
ARGS=("$@")

UNSET_NEXT=0
INDEX=0
for i in ${ARGS[*]}
    do
        [ 1 == $UNSET_NEXT ] && UNSET_NEXT=0 && unset ARGS[$INDEX]
        [ "--flavor" == "$i" ] && UNSET_NEXT=1 && unset ARGS[$INDEX]
        ((INDEX++))
    done

echo Passed args is : [ "${ARGS[*]}" ]

if [[ ! -x "$DART_EXE" ]]; then
  echo "Can't find dart executable file !"
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

if [[ "$JUST_REPLACE" == 0 ]]; then

  flutter ${ARGS[*]}

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

fi
