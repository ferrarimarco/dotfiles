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

.PHONY: help
help: ## Show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
