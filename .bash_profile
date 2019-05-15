#!/bin/bash

# Load .bashrc and other files...
for file in ~/.{path,bashrc,bash_prompt,aliases,functions,dockerfunc,extra,exports}; do
	if [[ -r "$file" ]] && [[ -f "$file" ]]; then
		# shellcheck source=/dev/null
		source "$file"
	fi
done
unset file
