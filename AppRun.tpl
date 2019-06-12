#!/bin/sh

export PATH="$PATH:$PWD:$PWD/bin:$PWD/usr/bin"

exec $APPDIR/APPLICATION "$@"
