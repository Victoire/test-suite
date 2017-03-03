# Victoire test suite

Victoire and its Widgets must implement Continous Integration with CircleCI and Behat tests.
This test suite must be used as a git submodule in your repository.

## Add submodule

```sh
git add submodule git@github.com:Victoire/test-suite.git victoire-test-suite
```

If you need to update the test suite, run `git submodule update --init` command.

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

## Add your first Behat test

`.feature` files must be stored in `Tests/Features` folder. 

##MIT License

License can be found [here](LICENSE).