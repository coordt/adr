.PHONY: clean clean-test clean-pyc clean-build docs help
.DEFAULT_GOAL := help

RELEASE_KIND := patch
SOURCE_DIR := adr

define BROWSER_PYSCRIPT
import os, webbrowser, sys

try:
	from urllib import pathname2url
except:
	from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT
BROWSER := python -c "$$BROWSER_PYSCRIPT"

BRANCH_NAME := $(shell echo $$(git rev-parse --abbrev-ref HEAD))
IN_MASTER := $(shell if [[ $$(echo $(BRANCH_NAME) | grep ^master | wc -w) -ne 0 ]] ; then echo "IN_MASTER" ; else echo "NOT_IN_MASTER" ; fi)
IS_RC := $(shell if [[ $$(cat .bumpversion.cfg | grep current.*rc | wc -w) -ne 0 ]] ; then echo "IS_RC" ; else echo "IS_NOT_RC" ; fi)
STATE := "$(IN_MASTER)_AND_$(IS_RC)"
EDIT_CHANGELOG_IF_EDITOR_SET := @bash -c "$(shell if [[ -n $$EDITOR ]] ; then echo "$$EDITOR CHANGELOG.md" ; else echo "" ; fi)"

help:
	@grep '^[a-zA-Z]' $(MAKEFILE_LIST) | sort | awk -F ':.*?## ' 'NF==2 {printf "\033[36m  %-25s\033[0m %s\n", $$1, $$2}'

clean: clean-build clean-pyc clean-test ## remove all build, test, coverage and Python artifacts

clean-build: ## remove build artifacts
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test: ## remove test and coverage artifacts
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache

lint: ## check style with flake8
	flake8 $(SOURCE_DIR) tests

test: ## run tests quickly with the default Python
	TESTING='true' pytest
	flake8 --count --output-file=reports/flake8.txt

test-all: ## run tests on every Python version with tox
	tox

coverage: ## check code coverage quickly with the default Python
	coverage run --source $(SOURCE_DIR) -m pytest
	coverage report -m
	coverage html
	$(BROWSER) htmlcov/index.html

docs: ## generate Sphinx HTML documentation, including API docs
	rm -f docs/api/$(SOURCE_DIR)*.rst
	sphinx-apidoc -o docs/api $(SOURCE_DIR)
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	$(BROWSER) docs/_build/html/index.html

servedocs: docs ## compile the docs watching for changes
	watchmedo shell-command -p '*.rst' -c '$(MAKE) -C docs html' -R -D .

release-helper:
	## DO NOT CALL DIRECTLY. It is used by release-{patch,major,minor,build}
	@echo "Branch In Use: $(BRANCH_NAME)"
ifeq ($(STATE),"NOT_IN_MASTER_AND_IS_RC")
	@echo "Error! Can't bump $(RELEASE_KIND) while on a branch and with an existing release candidate"
	exit
endif

	git fetch -p --all
	./bin/gen-codeowners.sh $(SOURCE_DIR)
	git add CODEOWNERS
	gitchangelog

ifeq ($(STATE),"IN_MASTER_AND_IS_RC")
	$(EDIT_CHANGELOG_IF_EDITOR_SET)
	bumpversion release --allow-dirty --tag
endif

ifeq ($(STATE),"IN_MASTER_AND_IS_NOT_RC")
	bumpversion $(RELEASE_KIND) --allow-dirty --no-commit
	gitchangelog
	$(EDIT_CHANGELOG_IF_EDITOR_SET)
	bumpversion release --allow-dirty --tag
endif

ifeq ($(STATE),"NOT_IN_MASTER_AND_IS_NOT_RC")
	@echo "$(BRANCH_NAME) being tagged"
	$(EDIT_CHANGELOG_IF_EDITOR_SET)
	bumpversion $(RELEASE_KIND) --allow-dirty --tag
endif
	git push origin $(BRANCH_NAME)
	git push --tags

set-release-major-env-var:
	$(eval RELEASE_KIND := major)

set-release-minor-env-var:
	$(eval RELEASE_KIND := minor)

set-release-patch-env-var:
	$(eval RELEASE_KIND := patch)

release-patch: set-release-patch-env-var release-helper  ## release a new patch version
	## If master: Release a new version: 1.1.1 -> 1.1.2 (or 1.1.1-rc0 -> 1.1.1)
	## If feature: Release a new release candidate with new version: 1.1.1 -> 1.1.2-rc0

release-minor: set-release-minor-env-var release-helper  ## release a new minor version
	## If master: Release a new version: 1.1.1 -> 1.2.0 (or if 1.2.0-rc0 -> 1.2.0)
	## If feature: Release a new release candidate with new version: 1.1.1 -> 1.2.0-rc0

release-major: set-release-major-env-var release-helper  ## release a new major version
	## If master:  Release a new version: 1.1.1 -> 2.0.0 (or if 2.0.0-rc0 -> 2.0.0)
	## If feature: Release a new release candidate with new version: 1.1.1 -> 2.0.0-rc0

bump-rc:  ## release a new build version
	## Increase build number: 1.2.3-rc4 -> 1.2.3-rc5
ifeq ($(STATE),"NOT_IN_MASTER_AND_IS_RC")
	git fetch -p --all
	./bin/gen-codeowners.sh $(SOURCE_DIR)
	git add CODEOWNERS
	gitchangelog
	$(EDIT_CHANGELOG_IF_EDITOR_SET)
	@echo "Tagging new build for $(BRANCH_NAME)"
	bumpversion build --allow-dirty --tag
	git push origin $(BRANCH_NAME)
	git push --tags
endif