#!/bin/bash

echo "memory_limit = 2048M" > /opt/circleci/php/$(phpenv global)/etc/conf.d/memory.ini
echo "always_populate_raw_post_data=-1" > /opt/circleci/php/$(phpenv global)/etc/conf.d/post_data.ini
if [ -n "${RUN_NIGHTLY_BUILD}" ]; then
  sed -i 's/^;//' /opt/circleci/php/$(phpenv global)/etc/conf.d/xdebug.ini
  echo "xdebug enabled"
fi

if [[ $1 == *"widget"* ]]; then
    php -d memory_limit=-1 /usr/local/bin/composer install --prefer-dist
    cd vendor/victoire/victoire/
    if [ -f Tests/config.yml ]; then
        sed -i '2i\    - { resource: ./../../../../../../../Tests/config.yml }' Tests/App/app/config/config_base.yml
    fi
fi

cp Tests/App/app/config/parameters.yml.dist Tests/App/app/config/parameters.yml
if [ -z "${RUN_NIGHTLY_BUILD}" ]; then
  sed -i '/CoverageContext/d' behat.yml
  sed -i '/CoverageContext/d' behat.yml.dist
  echo "CoverageContext disabled"
fi
npm install less
mkdir fails
php -d memory_limit=-1 /usr/local/bin/composer install --prefer-dist

if [[ $1 == *"widget"* ]]; then
    revision=$(cd ../../../ | git rev-parse HEAD)
    branch=$(cd ../../../ | git rev-parse --abbrev-ref HEAD)
    php -d memory_limit=-1 /usr/local/bin/composer require $1 dev-$branch#$revision --prefer-dist
fi

(cd Bundle/UIBundle/Resources/config/ && bower install)
php Tests/App/bin/console --env=ci doctrine:database:create --no-debug
php Tests/App/bin/console --env=ci doctrine:schema:create --no-debug
php Tests/App/bin/console --env=ci cache:clear --no-debug
php Tests/App/bin/console --env=domain cache:clear --no-debug
php Tests/App/bin/console --env=ci victoire:generate:view --no-debug
php Tests/App/bin/console --env=ci assets:install Tests/App/web --no-debug
php Tests/App/bin/console --env=ci bazinga:js-translation:dump --no-debug
php Tests/App/bin/console --env=ci fos:js:dump --target="Tests/App/web/js/fos_js_routes_test.js" --no-debug
php Tests/App/bin/console --env=domain fos:js:dump --target="Tests/App/web/js/fos_js_routes_domain.js" --no-debug
php Tests/App/bin/console --env=ci assetic:dump --no-debug
wget http://selenium-release.storage.googleapis.com/2.53/selenium-server-standalone-2.53.1.jar
nohup java -jar selenium-server-standalone-2.53.1.jar > /dev/null 2>&1 &
php Tests/App/bin/console --env=ci server:start 127.0.0.1:8000 -r Tests/App/app/config/router_ci.php --no-debug > server.log 2>&1
nohup Xvfb :99 -ac 2>/dev/null &
sleep 3
