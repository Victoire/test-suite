# Victoire test suite 

Victoire and its Widgets must implement Continous Integration with CircleCI and Behat tests.
This test suite must be used as a git submodule in your repository.

## Add submodule

```sh
git submodule add git@github.com:Victoire/test-suite.git victoire-test-suite
```

If you need to update the test suite, run `git submodule update --remote --merge` command.

## Add CircleCI configuration file

Add the following `circle.yml` config at your repository root.

```yml
machine:
  timezone:
    Europe/Paris
  hosts:
    fr.victoire.io: 127.0.0.1
    en.victoire.io: 127.0.0.1
  services:
    - redis
  php:
    version: 7.1.0

checkout:
  post:
    - git submodule sync
    - git submodule update --init

dependencies:
  override:
    - bash victoire-test-suite/dependencies.sh user/repo
  cache_directories:
    - ~/.composer/cache

test:
  override:
    - bash victoire-test-suite/circle.sh user/repo:
        parallel: true
    - bash victoire-test-suite/test.sh user/repo

general:
  artifacts:
    - "fails"
```

Replace `user/repo` with your own repository name.
This name must contain the string "widget" if you want to test a Widget.
If it doesn't, only Victoire core tests will be launched.


## Add CircleCI on Github

On your repository go to `Settings`/`Integrations & services`/`Services` and add CircleCI service.

## Add Behat tests

`.feature` files must be stored in `Tests/Features` folder.
Take a look at [Victoire `Tests/Features/Context` folder](https://github.com/Victoire/victoire/tree/master/Tests/Features/Context) to use contexts based on Victoire UI.

## Add Bundles to Victoire Test AppKernel

You may need to register your Bundle and other Bundles your required in Victoire Test Appkernel. You can do so by adding a `Tests/Bundles.php` file:

```php
<?php

$victoireTestBundles = [
    new Victoire\Widget\SearchBundle\VictoireWidgetSearchBundle(),
    new FOS\ElasticaBundle\FOSElasticaBundle(),
];
```

## Add config to Victoire Test environment

You may also need to add config. You can do so by adding a `Tests/config.yml` file:

```yml
fos_elastica:
    clients:
        default: { host: localhost, port: 9200 }
    indexes:
        ...
```

## Add new Contexts

You can also add specific Contexts for your Behat tests. Simply add as many Contexts as you need in a `Tests/Context` folder. These php files must match the pattern name `*Context.php`:

```php
<?php

namespace Victoire\Widget\SearchBundle\Tests\Context;

use Knp\FriendlyContexts\Context\RawMinkContext;

class WidgetContext extends RawMinkContext
{
    /**
     * @When /^I test a specific step from my Bundle/
     */
    public function iTestA specificStepFromMyBundle()
    {
        ...
    }
}

```

## Run external dependencies

You can run external dependencies by adding a `Tests/dependencies.sh` file.

## MIT License

License can be found [here](LICENSE).
