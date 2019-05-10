#!/usr/bin/env bash

defaults read NSGlobalDomain > NSGlobalDomain.out
defaults -currentHost read NSGlobalDomain > NSGlobalDomain-currentHost.out
defaults read > read.out
defaults -currentHost read > read-currentHost.out
