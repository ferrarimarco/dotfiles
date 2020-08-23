# Inspired by https://github.com/jessfraz/dotfiles

.PHONY: all
all: clean bin dotfiles ## Cleans stale dotfiles, installs bins and dotfiles.

.PHONY: bin
bin: ## Installs binaries
	@echo Installing binaries
	mkdir -p $(HOME)/bin;

	# add aliases for things in bin
	for file in $(shell find $(CURDIR)/bin -type f -not -name ".*.swp"); do \
		f=$$(basename $$file); \
		ln -sf $$file $(HOME)/bin/$$f; \
	done;

.PHONY: clean
clean: ## Uninstalls dotfiles and binaries
	@echo Cleaning
	for file in $(shell find $(HOME) -type l -ilname "*dotfiles*"); do \
		rm $$file; \
	done;
	sudo rm -f /etc/wsl.conf

.PHONY: dotfiles
dotfiles: ## Installs dotfiles
	@echo Installing dotfiles
	# add aliases for dotfiles
	for file in $(shell find $(CURDIR) -type f -path "*/\.*" -not -name ".gitignore" -not -name ".travis.yml" -not -path "*/\.git/*" -not -name ".*.swp"); do \
		f=$$(echo $$file | sed "s|^\$(CURDIR)/||"); \
		file_path=$(HOME)/$$f; \
		mkdir -p $$(dirname $$file_path); \
		ln -sfn $$file $$file_path; \
	done; \
	ln -sfn $(CURDIR)/gitignore $(HOME)/.gitignore;
	sudo cp $(HOME)/.config/wsl/wsl.conf /etc/wsl.conf;

.PHONY: test
test: shfmt super-linter ## Run tests

# if this session isn't interactive, then we don't want to allocate a
# TTY, which would fail, but if it is interactive, we do want to attach
# so that the user can send e.g. ^C through.
INTERACTIVE := $(shell [ -t 0 ] && echo 1 || echo 0)
ifeq ($(INTERACTIVE), 1)
	DOCKER_FLAGS += -t
endif

.PHONY: super-linter
super-linter: ## Run super-linter
	docker run --rm -t $(DOCKER_FLAGS) \
		-v "$(CURDIR)":/workspace \
		-w="/workspace" \
		-e ACTIONS_RUNNER_DEBUG=true \
		-e DEFAULT_WORKSPACE=/workspace \
		-e DISABLE_ERRORS=false \
		-e LINTER_RULES_PATH=/workspace \
		-e MULTI_STATUS=false \
		-e RUN_LOCAL=true \
		-e VALIDATE_ALL_CODEBASE=true \
		github/super-linter:V3.8.0

.PHONY: shfmt
shfmt: ## Run shfmt tests
	@echo Running shfmt
	for file in $(shell find $(CURDIR) -type f -not -path "*/\.git/*" -not -name "*.md"  -exec grep -Eq '^#!(.*/|.*env +)(sh|bash|ksh)' {} \; -print); do \
		f=$$(echo $$file | sed "s|^\$(CURDIR)/||"); \
		echo "Linting $$f"; \
		shfmt -d "$$f" || exit 1 ; \
	done;

.PHONY: help
help: ## Show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
