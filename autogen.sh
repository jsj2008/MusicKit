#!/bin/sh
# Top level configuration script for the MusicKit. This is used to bootstrap the configure generator. You
# will typically want to run this if you are checking the source straight out of the
# repository or the distributed configure script is too old.

autoconf
# We include the fink locations (on MacOS X) into the default locations to search for
# libraries to ease bootstrapping. This has no effect on Linux etc.
# ./configure
./configure CPPFLAGS=-I/sw/include LDFLAGS=-L/sw/lib 
make
