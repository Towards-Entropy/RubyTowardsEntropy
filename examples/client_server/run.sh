#!/bin/bash

# Start the web server in the background
rackup &

# Store the web server's process ID
SERVER_PID=$!

# Give the server a few seconds to start
sleep 3

# Run the client script
ruby client.rb

# Kill the web server
kill $SERVER_PID