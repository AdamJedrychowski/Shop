#!/bin/bash

while ! netcat -z -v -w5 "mouse.db.elephantsql.com" 5432; do
    echo "Waiting for database connection..."
    sleep 5
done
