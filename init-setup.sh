#!/bin/bash

if [[ `git status --porcelain` ]]; then
  echo "we nave changes"
else
  echo "no changes"
fi