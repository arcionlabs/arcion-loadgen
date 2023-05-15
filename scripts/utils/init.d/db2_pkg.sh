#!/usr/bin/env bash

sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y file
sudo apt-get install libaio1 libstdc++6:i386 libpam0g:i386
sudo apt-get  install binutils

# install on the machine where thet setup is run
sudo apt-get install libxrender1

# https://www.ibm.com/support/pages/unsatisfiedlinkerror-cannot-open-shared-object-file-libxtstso6
sudo apt-get install libxtst-dev
