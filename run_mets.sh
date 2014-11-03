#!/bin/bash

PATH=$PATH:/usr/local/bin
. /usr/local/lib/rvm

DIR=/data/rails/dig_flow
cd $DIR
RAILS_ENV=production ruby ./run_mets.rb >> $DIR/log/mets.log 2>&1
