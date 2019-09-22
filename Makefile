# From https://github.com/jessfraz/dotfiles

.PHONY: all
all: bin dotfiles ## Installs the bin and etc directory files and the dotfiles.

.PHONY: bin
bin: ## Installs the bin directory files.
	mkdir -p $(HOME)/bin;

	# add aliases for things in bin
	for file in $(shell find $(CURDIR)/bin -type f -not -name ".*.swp"); do \
		f=$$(basename $$file); \
		ln -sf $$file $(HOME)/bin/$$f; \
	done;

.PHONY: dotfiles
dotfiles: ## Installs the dotfiles.
	# add aliases for dotfiles
	for file in $(shell find $(CURDIR) -type f -path "*/\.*" -not -name ".gitignore" -not -name ".travis.yml" -not -path "*/\.git/*" -not -name ".*.swp"); do \
		f=$$(echo $$file | sed "s|^\$(CURDIR)/||"); \
		file_path=$(HOME)/$$f; \
		mkdir -p $$(dirname $$file_path); \
		ln -sfn $$file $$file_path; \
	done; \
	ln -fn $(CURDIR)/gitignore $(HOME)/.gitignore;
	git update-index --skip-worktree $(CURDIR)/.gitconfig;
	ln -snf $(CURDIR)/.bash_profile $(HOME)/.profile;

.PHONY: test
test: psscriptanalyzer shellcheck ## Runs all the tests on the files in the repository.

# if this session isn't interactive, then we don't want to allocate a
# TTY, which would fail, but if it is interactive, we do want to attach
# so that the user can send e.g. ^C through.
INTERACTIVE := $(shell [ -t 0 ] && echo 1 || echo 0)
ifeq ($(INTERACTIVE), 1)
	DOCKER_FLAGS += -t
endif

.PHONY: psscriptanalyzer
psscriptanalyzer: ## Runs PSScriptAnalyzer tests on the scripts
	docker run --rm -i $(DOCKER_FLAGS) \
		--name df-psscriptanalyzer \
		-v $(CURDIR):/usr/src:ro \
		mcr.microsoft.com/powershell \
		pwsh -command "Save-Module -Name PSScriptAnalyzer -Path .; Import-Module .\PSScriptAnalyzer; Invoke-ScriptAnalyzer -Path /usr/src -Recurse"

.PHONY: shellcheck
shellcheck: ## Runs shellcheck tests on the scripts.
	docker run --rm -i $(DOCKER_FLAGS) \
		--name df-shellcheck \
		-v $(CURDIR):/usr/src:ro \
		ferrarimarco/shellcheck

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
