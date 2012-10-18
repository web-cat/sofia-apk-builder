#!/bin/bash
rm log/sinatra.log || true

RACK_ENV=development rackup &

while [ ! -f log/sinatra.log ]
do
  sleep 1
done

tail -f log/sinatra.log
