#!/usr/bin/env bash

defaults read NSGlobalDomain > NSGlobalDomain-before.out
defaults -currentHost read NSGlobalDomain > NSGlobalDomain-currentHost-before.out
defaults read > read-before.out
defaults -currentHost read > read-currentHost-before.out

read -n1 -rsp "Change the settings and press any key to continue...\n" key

defaults read NSGlobalDomain > NSGlobalDomain-after.out
defaults -currentHost read NSGlobalDomain > NSGlobalDomain-currentHost-after.out
defaults read > read-after.out
defaults -currentHost read > read-currentHost-after.out
