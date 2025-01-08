#!/usr/bin/env bash

# Find a better way of doinf this
git config --global --unset diff.external
git diff
git config --global diff.external difft
