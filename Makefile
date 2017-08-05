PATH        := ./node_modules/.bin:${PATH}

NPM_PACKAGE := $(shell node -e 'process.stdout.write(require("./package.json").name)')
NPM_VERSION := $(shell node -e 'process.stdout.write(require("./package.json").version)')

TMP_PATH    := /tmp/${NPM_PACKAGE}-$(shell date +%s)

REMOTE_NAME ?= origin
REMOTE_REPO ?= $(shell git config --get remote.${REMOTE_NAME}.url)

CURR_HEAD   := $(firstword $(shell git show-ref --hash HEAD | cut -b -6) master)
GITHUB_PROJ := https://github.com//mcecot/${NPM_PACKAGE}


build: decaf lint browserify test coverage todo 

decaf:
	gulp coffee --require coffee-script/register

lint:
	coffeelint gulpfile.coffee index.coffee test -f ./coffeelint.json
	eslint .

test: lint
	mocha ./test/*.coffee --require coffee-script/register

coverage:
	-rm -rf coverage
	istanbul cover node_modules/mocha/bin/_mocha -- ./test/*.coffee --require coffee-script/register

coveralls:
	cat ./coverage/lcov.info | ./node_modules/coveralls/bin/coveralls.js

report-coverage: coverage

test-ci: coverage

browserify:
	-rm -rf ./dist
	mkdir dist
	# Browserify
	( printf "/*! ${NPM_PACKAGE} ${NPM_VERSION} ${GITHUB_PROJ} @license MIT */" ; \
		browserify ./ -s markdownitCheckbox \
		) > dist/${NPM_PACKAGE}.js

minify: browserify
	# Minify
	uglifyjs dist/${NPM_PACKAGE}.js -b beautify=false,ascii_only=true -c -m \
		--preamble "/*! ${NPM_PACKAGE} ${NPM_VERSION} ${GITHUB_PROJ} @license MIT */" \
		> dist/${NPM_PACKAGE}.min.js

todo:
	@echo ""
	@echo "TODO list"
	@echo "---------"
	@echo ""
	grep 'TODO' -n -r ./lib 2>/dev/null || test true

clean:
	-rm -rf ./coverage/
	-rm -rf ./dist/

.PHONY: clean lint test todo coverage report-coverage test-ci build browserify minify
.SILENT: help lint test todo
