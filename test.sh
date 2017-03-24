#!/bin/bash

if [[ $1 == "victoire/victoire" ]]; then
    wget http://psvcg.coreteks.org/php-semver-checker-git.phar
    php php-semver-checker-git.phar suggest --allow-detached -vvv --details --include-before=src --include-after=src | awk '/Suggested semantic version: / {print $4}' | awk '{ print "{\"Suggested semantic version\":\"" $1 "\"}" }' > $CIRCLE_TEST_REPORTS/semver.json
    if [ -n "${RUN_NIGHTLY_BUILD}" ]; then
        mkdir -p cp $CIRCLE_TEST_REPORTS/coverage && cp -R $(php -r "echo sys_get_temp_dir();")/Victoire/logs/coverage $CIRCLE_TEST_REPORTS
    fi
fi
