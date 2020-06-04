# Contributing to scadnano
First off, thanks for taking the time to contribute!

The following is a set of guidelines for contributing to scadnano.
These are mostly guidelines, not rules. Use your best judgement, and
feel free to prose changes to this doucment in a pull request.

## What should I know before I get started?

### Dart

scadnano is written in [Dart](https://dart.dev/). You will need to
[get the Dark SDK](https://dart.dev/get-dart) to develop.

### Packages

scadnano uses many packages, all of which can be found in the
[pubspec.yaml](pubspec.yaml) file.
These packages can be installed using [`pub get`](https://dart.dev/guides/packages#getting-packages).

Here's a list of the big ones:

* [OverReact](https://pub.dev/packages/over_react) - A Dart wrapper
around the JavaScript [React](https://reactjs.org/) and [React Redux](https://react-redux.js.org/)
libraries and is responsible for the [*view*](lib/src/view)
component of the application.

* [redux.dart](https://pub.dev/packages/redux) - A Dart wrapper
around the JavaScript [Redux](https://redux.js.org/) and is
responsible for the [*state*](lib/src/state),
[*reducers*](lib/src/reducers), [*action*](lib/src/actions),
and [*middleware*](lib/src/middleware)
components of the application.

* [built_value](https://pub.dev/packages/built_value),
[built_collection](https://pub.dev/packages/built_collection) -
Immutable values and collections to aid with the [immutability
required by Redux](https://redux.js.org/faq/immutable-data#why-is-immutability-required-by-redux)

There are many more, but this ones listed here should be sufficient
to implement most features.

## Making Contributions

scadnano can be developed locally.

### Cloning

The first step is creating your own clone.

```
git clone https://github.com/UC-Davis-molecular-computing/scadnano.git
```

Changes to scadnano should be pushed to the
[`dev`](https://github.com/UC-Davis-molecular-computing/scadnano/tree/dev)
branch. So switch to the `dev` branch:

```
git checkout dev
```

Next install all the dependencies (make sure you have [installed Dart](#dart)):

```
pub get
```


### Running a Development Server

To run a development server to test the application, use the
[`webdev`](https://dart.dev/tools/webdev) tool. This tool can
be installed by following instructions [here](https://dart.dev/tools/webdev#setupv).
Run `webdev serve` in the command line to compile your code
with the [Dart dev compiler](https://dart.dev/tools/dartdevc)
(dartdevc) and spin up a [development
server](https://dart.dev/tools/webdev#serve).

There are a couple benefits of using `webdev serve`:
1. Unlike the [dart2js](https://dart.dev/tools/dart2js)
compiler, dartdevc supports incremental compilation, so
you can edit your Dart files, refresh your browser, and see your
edits immediately. This speed is possible because dartdevc compiles
only updated modules. Note that the first compilation will take the longest.

2. dartdevc emits modular
JavaScript, which allows for debugging with tools such as
[Chrome DevTools](https://developers.google.com/web/tools/chrome-devtools)
and [Firefox Developer Tools](https://developer.mozilla.org/en-US/docs/Tools). You can set breakpoints on the Dart source code and
step through the code as if it was the Dart code that was running
(rather than the compiled JavaScript).

You may also find the [React Developer Tools](https://chrome.google.com/webstore/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi?hl=en)
and [Redux DevTools](https://chrome.google.com/webstore/detail/redux-devtools/lmhkpmbekcpmknklioeibfkpmmfibljd?hl=en)
extensions helpful for debugging and profiling.


### Running Tests

Unit tests are contained in the [test](test/) directory.

The repository provides a test script [test.sh](test.sh), which
provides common utilities for running unit tests. All unit tests
can be run by `bash test.sh`. To see more options, run
`bash test.sh -h`.

Please add unit tests whenever possible. Currently, there are unit
tests for [Redux reducers](test/reducer_test.dart) and a few tests for
[React components](test/components). While Redux reducers tests are fairly
straightforward to make, adding React components and Redux middleware
unit tests is an [ongoing issue](https://github.com/UC-Davis-molecular-computing/scadnano/issues/32).

### Building

Building isn't necessary for the most part since the repository
has a [Github Action](https://github.com/UC-Davis-molecular-computing/scadnano/actions?query=workflow%3A%22github+pages%22) that automatically builds and deploys changes
in the master branch.

Nevertheless, you may find it useful to build with the production
compiler `dart2js` for profiling purposes or debugging some
production-specific bug. You can tell `webdev` to compile with
the `dart2js` compiler by adding the `--release` flag:
```
webdev serve --release
```

### Troubleshooting

(TODO): Add common errors here.


## Pushing to the Repository

Make sure you pull changes from the repository and resolve any
conflicts before pushing to the `dev` branch. All local commits
should be push to the `dev` branch.

Pull request can be made from `dev` to `master`, but make sure that
`dev` is working before merging to `master` as all changes to `master`
are automatically built and deployed to [scadnano.org](scadnano.org).

## Styleguide

Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
which should come along in most IDEs in the form of plugins
and extensions. Visual Studio Code offers an [extension](https://dartcode.org/)
and WebStorm offers a [plugin](https://plugins.jetbrains.com/plugin/6351-dart).
The line length should be configued to 110, as the style guide limit of 80
is a bit too restrictive.