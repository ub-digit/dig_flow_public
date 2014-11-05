#!/bin/bash

rm -f Gemfile.lock
git pull
rm -f Gemfile.lock
bundle install
rake db:migrate RAILS_ENV=production
bundle exec rake assets:precompile
touch tmp/restart.txt
#sudo /etc/init.d/resque restart
