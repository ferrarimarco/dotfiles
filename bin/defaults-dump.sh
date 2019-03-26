#!/usr/bin/env bash

defaults read NSGlobalDomain > NSGlobalDomain
defaults -currentHost read NSGlobalDomain > NSGlobalDomain-currentHost
defaults read > read
defaults -currentHost read > read-currentHost
