#!/bin/bash

# Calculate sum of return codes in order to detect errors
# http://stackoverflow.com/questions/6348902/how-can-i-add-numbers-in-a-bash-script/6348945#6348945
sum=0

echo "memory_limit = 2048M" > /opt/circleci/php/$(phpenv global)/etc/conf.d/memory.ini
sum=$(( $sum + $? ))
echo "always_populate_raw_post_data=-1" > /opt/circleci/php/$(phpenv global)/etc/conf.d/post_data.ini
if [ -n "${RUN_NIGHTLY_BUILD}" ]; then
  sed -i 's/^;//' /opt/circleci/php/$(phpenv global)/etc/conf.d/xdebug.ini
  sum=$(( $sum + $? ))
  echo "xdebug enabled"
fi

if [[ $1 != *"victoire/victoire"* ]]; then
    php -d memory_limit=-1 /usr/local/bin/composer install --prefer-source
    sum=$(( $sum + $? ))
    if [ -f Tests/config.yml ]; then
        sed -i '2i\    - { resource: ./../../../../../../../Tests/config.yml }' vendor/victoire/victoire/Tests/App/app/config/config_base.yml
    fi
    cd vendor/victoire/victoire/
fi

cp Tests/App/app/config/parameters.yml.dist Tests/App/app/config/parameters.yml
if [ -z "${RUN_NIGHTLY_BUILD}" ]; then
  sed -i '/CoverageContext/d' behat.yml.dist
  echo "CoverageContext disabled"
fi
npm install less@2.7.2 && \
mkdir fails && \
php -d memory_limit=-1 /usr/local/bin/composer install --prefer-dist
sum=$(( $sum + $? ))

if [[ $1 != *"victoire/victoire"* ]]; then
    revision=$(cd ../../../ && git rev-parse HEAD)

    url="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/pulls/$CIRCLE_PR_NUMBER";
    if [ -z "${GITHUB_TOKEN}" ]; then
        branch=$(curl -s "$url" | jq -r '.head.ref')
    else
        branch=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$url" | jq '.head.ref' | tr -d '""')
    fi
    # https://stackoverflow.com/questions/584894/environment-variable-substitution-in-sed
    # Manage varenv in sed
    sed -i 's@"name": "victoire/victoire",@"name": "victoire/victoire","repositories": [{"type": "vcs", "url": "https://github.com/'"${CIRCLE_PR_USERNAME}"'/'"${CIRCLE_PR_REPONAME}"'"}],@' composer.json

    php -d memory_limit=-1 /usr/local/bin/composer require $1:dev-$branch#$revision --prefer-dist
    sum=$(( $sum + $? ))
fi

if [ -f ../../../Tests/dependencies.sh ]; then
    bash ../../../Tests/dependencies.sh
fi

(cd Bundle/UIBundle/Resources/config/ && bower install)
php Tests/App/bin/console --env=ci doctrine:database:create --no-debug && \
php Tests/App/bin/console --env=ci doctrine:schema:create --no-debug && \
php Tests/App/bin/console --env=ci cache:clear --no-debug && \
php Tests/App/bin/console --env=domain cache:clear --no-debug && \
php Tests/App/bin/console --env=ci victoire:generate:view --no-debug && \
php Tests/App/bin/console --env=ci assets:install Tests/App/web --no-debug && \
php Tests/App/bin/console --env=ci bazinga:js-translation:dump --no-debug && \
php Tests/App/bin/console --env=domain bazinga:js-translation:dump --no-debug && \
php Tests/App/bin/console --env=ci fos:js:dump --target="Tests/App/web/js/fos_js_routes_test.js" --no-debug && \
php Tests/App/bin/console --env=domain fos:js:dump --target="Tests/App/web/js/fos_js_routes_domain.js" --no-debug && \
php Tests/App/bin/console --env=ci assetic:dump --no-debug
sum=$(( $sum + $? ))

wget http://selenium-release.storage.googleapis.com/2.53/selenium-server-standalone-2.53.1.jar
nohup java -jar selenium-server-standalone-2.53.1.jar > /dev/null 2>&1 &
php Tests/App/bin/console --env=ci server:start 127.0.0.1:8000 -r Tests/App/app/config/router_ci.php --docroot=Tests/App/web/ --no-debug > server.log 2>&1
sum=$(( $sum + $? ))
nohup Xvfb :99 -ac 2>/dev/null &
sleep 3

exit $sum