#!/bin/bash

if [ "$1" == "off" ]; then
  echo "switch off maintenance mode"
  ln -sf /home/deploy/exchangepro/shared/config/nginx.conf /etc/nginx/conf.d/exchangepro.conf
  service nginx reload
else
  echo "switch on maintenance mode"
  ln -sf /home/deploy/exchangepro/shared/config/nginx_maintenance.conf /etc/nginx/conf.d/exchangepro.conf
  service nginx reload
fi
