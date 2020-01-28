#!/usr/bin/env bash

echo "Reading defaults..."
defaults read NSGlobalDomain >NSGlobalDomain-before.out
defaults -currentHost read NSGlobalDomain >NSGlobalDomain-currentHost-before.out
defaults read >read-before.out
defaults -currentHost read >read-currentHost-before.out

read -n1 -rsp $'Change the settings and press any key to continue...\n'

defaults read NSGlobalDomain >NSGlobalDomain-after.out
defaults -currentHost read NSGlobalDomain >NSGlobalDomain-currentHost-after.out
defaults read >read-after.out
defaults -currentHost read >read-currentHost-after.out

echo "Diffing..."
diff NSGlobalDomain-before.out NSGlobalDomain-after.out
diff NSGlobalDomain-currentHost-before.out NSGlobalDomain-currentHost-after.out
diff read-currentHost-before.out read-currentHost-after.out
