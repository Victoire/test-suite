#!/bin/bash

if [[ $1 == *"widget"* ]]; then
    composer install --prefer-dist
    cd vendor/victoire/victoire/
fi

cp Tests/Functionnal/app/config/parameters.yml.dist Tests/Functionnal/app/config/parameters.yml
echo "memory_limit = 2048M" > /opt/circleci/php/$(phpenv global)/etc/conf.d/memory.ini
echo "always_populate_raw_post_data=-1" > /opt/circleci/php/$(phpenv global)/etc/conf.d/post_data.ini
if [ -n "${RUN_NIGHTLY_BUILD}" ]; then
  sed -i 's/^;//' /opt/circleci/php/$(phpenv global)/etc/conf.d/xdebug.ini
  echo "xdebug enabled"
fi
if [ -z "${RUN_NIGHTLY_BUILD}" ]; then
  sed -i '/CoverageContext/d' behat.yml
  sed -i '/CoverageContext/d' behat.yml.dist
  echo "CoverageContext disabled"
fi
npm install less
mkdir fails
composer install --prefer-dist

if [[ $1 == *"widget"* ]]; then
    revision=$(cd ../../../ | git rev-parse HEAD)
    composer require friendsofvictoire/$1#$revision
fi

bower install
php Tests/Functionnal/bin/console --env=ci doctrine:database:create --no-debug
php Tests/Functionnal/bin/console --env=ci doctrine:schema:create --no-debug
php Tests/Functionnal/bin/console --env=ci cache:warmup --no-debug
php Tests/Functionnal/bin/console --env=domain cache:warmup --no-debug
php Tests/Functionnal/bin/console --env=ci victoire:generate:view --no-debug
php Tests/Functionnal/bin/console --env=ci assets:install Tests/Functionnal/web --no-debug
php Tests/Functionnal/bin/console --env=ci bazinga:js-translation:dump --no-debug
php Tests/Functionnal/bin/console --env=ci fos:js:dump --target="Tests/Functionnal/web/js/fos_js_routes_test.js" --no-debug
php Tests/Functionnal/bin/console --env=domain fos:js:dump --target="Tests/Functionnal/web/js/fos_js_routes_domain.js" --no-debug
php Tests/Functionnal/bin/console --env=ci assetic:dump --no-debug
wget http://selenium-release.storage.googleapis.com/2.53/selenium-server-standalone-2.53.1.jar
nohup java -jar selenium-server-standalone-2.53.1.jar > /dev/null 2>&1 &
php Tests/Functionnal/bin/console --env=ci server:start 127.0.0.1:8000 -r Tests/Functionnal/app/config/router_ci.php --no-debug > server.log 2>&1
nohup Xvfb :99 -ac 2>/dev/null &
sleep 3