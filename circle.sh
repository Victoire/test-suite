#!/bin/bash

# This file run Behat tests on CircleCI with parallelization.
# It search in multiple directories for feature files and run Behat.

declare -a path

if [[ $1 != *"victoire/victoire"* ]]; then
    path=Tests/Features/CurrentWidget
    mkdir vendor/victoire/victoire/$path
    cp -r Tests/Features/* vendor/victoire/victoire/$path
    cd vendor/victoire/victoire/
else
    path=Tests/Features
fi

if [ -z "${RUN_NIGHTLY_BUILD}" ]; then
    if [ -z "$CIRCLE_NODE_INDEX" ]; then
      echo "No parrallelism found, setting defaults to run all tests."
      CIRCLE_NODE_TOTAL=1
      CIRCLE_NODE_INDEX=0
    fi

    echo "\$CIRCLE_NODE_TOTAL = $CIRCLE_NODE_TOTAL"
    echo "\$CIRCLE_NODE_INDEX = $CIRCLE_NODE_INDEX"

    # Don't rely on default order
    # http://serverfault.com/questions/181787/find-command-default-sorting-order/181815#181815
    availableScenarios=($(./vendor/bin/behat $path --dry-run | grep "Scenario: " | awk '{print $(NF)}' > var/scenarios))
    let "scenarioCount = ${#availableScenarios[@]}"
    echo "$scenarioCount features found"

    let "scenariosToRunCount = scenarioCount / $CIRCLE_NODE_TOTAL"
    let "modulo = scenarioCount % $CIRCLE_NODE_TOTAL"
    if [ "$modulo" -ne 0 ]; then
        let "scenariosToRunCount += 1"
    fi
    fromScenarioIndex=1

    let "toScenarioIndex = (scenariosToRunCount) * $CIRCLE_NODE_INDEX - 1"
    let "fromScenarioIndex = toScenarioIndex - scenariosToRunCount + 1"
    echo "$scenariosToRunCount features to run here [$fromScenarioIndex-$toScenarioIndex]"

    echo "scenarios:"

    scenariosToRun=()
    for ((i=0; i < ${#availableScenarios[@]}; i++)); do
        if [ "$i" -ge $fromScenarioIndex ] && [ "$i" -le $toScenarioIndex ]; then
            echo "- ${availableScenarios[$i]}"
            scenariosToRun+=(${availableScenarios[$i]})
        fi
    done

    # Calculate sum of return codes in order to detect errors
    # http://stackoverflow.com/questions/6348902/how-can-i-add-numbers-in-a-bash-script/6348945#6348945
    sum=0
    if [ "${#scenariosToRun[@]}" -gt 0 ]; then
        for ((i=0; i < ${#scenariosToRun[@]}; i++)); do
            echo "bin/behat -vv ${scenariosToRun[$i]}"
            time bin/behat -vv ${scenariosToRun[$i]}
            echo "Running ./vendor/bin/behat --format=pretty --out=std --format=junit --out=$CIRCLE_TEST_REPORTS/$i/junit --rerun="return.log" ${scenariosToRun[$i]}"
            time ./vendor/bin/behat --format=pretty --out=std --format=junit --out=$CIRCLE_TEST_REPORTS/$i/junit ${scenariosToRun[$i]}
            return=$?
            echo "return code = ${return}"
            sum=$(( $sum + $return ))
        done
    else
        echo "No test to run (issue related to modulo)"
    fi
    echo "sum of Behat return codes = ${sum}"
    exit $sum
fi
