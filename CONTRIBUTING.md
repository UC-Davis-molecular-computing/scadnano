# Contributing to scadnano
First off, thanks for taking the time to contribute!

The following is a set of guidelines for contributing to scadnano.
These are mostly guidelines, not rules. Use your best judgement, and
feel free to prose changes to this document in a pull request.

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


## Pushing to the repository and documenting changes

Make sure you pull changes from the repository and resolve any
conflicts before pushing to the `dev` branch. All local commits
should be push to the `dev` branch.

Pull requests (abbreviated PR) can be made from `dev` to `master`, but make sure that
`dev` is working before merging to `master` as all changes to `master`
are automatically built and deployed to https://scadnano.org.

We have an automated release system (through a GitHub action) that automatically creates release notes.

Although the GitHub web interface abbreviates long commit messages, the full commit message is included for each commit in a PR.

However, commit descriptions (in GitHub desktop these are two separate fields; on the command line they appear to be indicated by two separate usages of the `-m` flag: https://stackoverflow.com/questions/16122234/how-to-commit-a-change-with-both-message-and-description-from-the-command-li).

So make sure that everything people should see in the automatically generated release notes is included in the commit message.

Users can read the description by clicking on the link to the commit or the pull request, but anything is put there, then the commit message should say something like "click on commit/PR for more details".

See here for an example: https://github.com/UC-Davis-molecular-computing/scadnano/releases/tag/v0.9.3

So the steps are:

1. Commit changes to the `dev` branch. There will typically be several of these. Despite GitHub's suggestions to keep commit messages short and put longer text in descriptions, because only the commit message is included in the release notes, it's okay to put more detail (but very long stuff should go in the description, or possibly documentation such as the README.md file).

2. One of the changes committed should change the version number. This is a string of the form `"MAJOR.MINOR.PATCH"`, e.g., `"0.9.3"`
    - For the web interface repo scadnano, this is located at the top of the file https://github.com/UC-Davis-molecular-computing/scadnano/blob/master/lib/src/constants.dart
    - For the Python library repo scadnano-python-package, this is located in two places: the bottom of the file https://github.com/UC-Davis-molecular-computing/scadnano-python-package/blob/master/scadnano/_version.py (as `__version__ = "0.9.3"` or something similar) and the near the top of the file https://github.com/UC-Davis-molecular-computing/scadnano-python-package/blob/master/scadnano/scadnano.py (as `__version__ = "0.9.3"` or something similar). This latter one is only there for users who do not install from PyPI, and who simply download the file scadnano.py to put it in a directory with their script).

3. Ensure all unit tests pass.

4. In the Python repo, ensure that the documentation is generated without errors. From the subfolder `doc`, run the command `make html`, ensure there are no errors, and inspect the documentation it generates in the folder `build`.

5. Create a PR to merge changes from dev into master and then do the merge.)

6. Once the PR changes are merged, a release will be automatically created here: https://github.com/UC-Davis-molecular-computing/scadnano/releases or https://github.com/UC-Davis-molecular-computing/scadnano-python-package/releases. It will have a title that is a placerholder, which is a reminder to change its title and tag. Each commit will be documented, with the commit message (but not description) included in the release notes.

7. Change the title and tag  to the version number with a `v` prepended, e.g., `v0.9.3`. It is imperative to change the tag before the next merge into master, or else the release (which defaults to `latest`) will be overwritten.

8. In the Python repo, update the PyPI package by running the following two commands from the root of the repo, replacing `scadnano-0.9.3.tar.gz` with the appropriate version number:
    ```
    $ python setup.py sdist
    $ twine upload dist/scadnano-0.9.3.tar.gz
    ```
    The latter command uploads to PyPI, and requires permissions to be set up; see https://medium.com/@joel.barmettler/how-to-upload-your-python-package-to-pypi-65edc5fe9c56



## Styleguide

Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
which should come along in most IDEs in the form of plugins
and extensions. Visual Studio Code offers an [extension](https://dartcode.org/)
and WebStorm offers a [plugin](https://plugins.jetbrains.com/plugin/6351-dart).
The line length should be configured to 110, as the style guide limit of 80
is a bit too restrictive.

