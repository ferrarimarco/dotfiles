# Inspired by https://github.com/jessfraz/dotfiles

.PHONY: all
all: bin dotfiles ## Installs the bin and etc directory files and the dotfiles.

.PHONY: bin
bin:
	@echo Installing binaries
	mkdir -p $(HOME)/bin;

	# add aliases for things in bin
	for file in $(shell find $(CURDIR)/bin -type f -not -name ".*.swp"); do \
		f=$$(basename $$file); \
		ln -sf $$file $(HOME)/bin/$$f; \
	done;

.PHONY: dotfiles
dotfiles:
	@echo Installing dotfiles
	# add aliases for dotfiles
	for file in $(shell find $(CURDIR) -type f -path "*/\.*" -not -name ".gitignore" -not -name ".travis.yml" -not -path "*/\.git/*" -not -name ".*.swp"); do \
		f=$$(echo $$file | sed "s|^\$(CURDIR)/||"); \
		file_path=$(HOME)/$$f; \
		mkdir -p $$(dirname $$file_path); \
		ln -sfn $$file $$file_path; \
	done; \
	ln -sfn $(CURDIR)/gitignore $(HOME)/.gitignore;

.PHONY: test
test: shellcheck psscriptanalyzer

# if this session isn't interactive, then we don't want to allocate a
# TTY, which would fail, but if it is interactive, we do want to attach
# so that the user can send e.g. ^C through.
INTERACTIVE := $(shell [ -t 0 ] && echo 1 || echo 0)
ifeq ($(INTERACTIVE), 1)
	DOCKER_FLAGS += -t
endif

.PHONY: psscriptanalyzer
psscriptanalyzer:
	@echo Running PSScriptAnalyzer
	docker run --rm -i $(DOCKER_FLAGS) \
		--name df-psscriptanalyzer \
		-v $(CURDIR):/usr/src:ro \
		mcr.microsoft.com/powershell \
		pwsh -command "Save-Module -Name PSScriptAnalyzer -Path .; Import-Module .\PSScriptAnalyzer; Invoke-ScriptAnalyzer -EnableExit -Path /usr/src -Recurse"

.PHONY: shellcheck
shellcheck:
	@echo Running shellcheck
	for file in $(shell find $(CURDIR) -type f -exec grep -Eq '^#!(.*/|.*env +)(sh|bash|ksh)' {} \; -print | while IFS="" read -r file); do
		f=$$(echo $$file | sed "s|^\$(CURDIR)/||");
		docker run --rm -i $(DOCKER_FLAGS) \
			-v $(CURDIR):/mnt:ro \
			koalaman/shellcheck:v0.7.0 "$$f";
	done;

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
