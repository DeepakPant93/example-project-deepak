# example-project-deepak

[![Release](https://img.shields.io/github/v/release/DeepakPant93/example-project-deepak)](https://img.shields.io/github/v/release/DeepakPant93/example-project-deepak)
[![Build status](https://img.shields.io/github/actions/workflow/status/DeepakPant93/example-project-deepak/main.yml?branch=main)](https://github.com/DeepakPant93/example-project-deepak/actions/workflows/main.yml?query=branch%3Amain)
[![codecov](https://codecov.io/gh/DeepakPant93/example-project-deepak/branch/main/graph/badge.svg)](https://codecov.io/gh/DeepakPant93/example-project-deepak)
[![Commit activity](https://img.shields.io/github/commit-activity/m/DeepakPant93/example-project-deepak)](https://img.shields.io/github/commit-activity/m/DeepakPant93/example-project-deepak)
[![License](https://img.shields.io/github/license/DeepakPant93/example-project-deepak)](https://img.shields.io/github/license/DeepakPant93/example-project-deepak)

This is a template repository for Python projects that use Poetry for their dependency management.

-   **Github repository**: <https://github.com/DeepakPant93/example-project-deepak/>
-   **Documentation** <https://DeepakPant93.github.io/example-project-deepak/>

## Getting started with your project

First, create a repository on GitHub with the same name as this project, and then run the following commands:

```bash
git init -b main
git add .
git commit -m "init commit"
git remote add origin git@github.com:DeepakPant93/example-project-deepak.git
git push -u origin main
```

Finally, install the environment and the pre-commit hooks with

```bash
make install
```

You are now ready to start development on your project!
The CI/CD pipeline will be triggered when you open a pull request, merge to main, or when you create a new release.

To finalize the set-up for publishing to PyPI or Artifactory, see [here](https://fpgmaas.github.io/cookiecutter-poetry/features/publishing/#set-up-for-pypi).
For activating the automatic documentation with MkDocs, see [here](https://fpgmaas.github.io/cookiecutter-poetry/features/mkdocs/#enabling-the-documentation-on-github).
To enable the code coverage reports, see [here](https://fpgmaas.github.io/cookiecutter-poetry/features/codecov/).

## Releasing a new version

-   Create an API Token on [PyPI](https://pypi.org/).
-   Add the API Token to your projects secrets with the name `PYPI_TOKEN` by visiting [this page](https://github.com/DeepakPant93/example-project-deepak/settings/secrets/actions/new).
-   Create a [new release](https://github.com/DeepakPant93/example-project-deepak/releases/new) on Github.
-   Create a new tag in the form `*.*.*`.
-   For more details, see [here](https://fpgmaas.github.io/cookiecutter-poetry/features/cicd/#how-to-trigger-a-release).

---

Repository initiated with [fpgmaas/cookiecutter-poetry](https://github.com/fpgmaas/cookiecutter-poetry).
