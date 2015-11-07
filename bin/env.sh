#! /bin/bash
/usr/bin/env $(cat ".env" | grep "^[^#]*=.*" | xargs) $*
