#!/bin/bash
set -e

echo "Building Java MapReduce project..."
(cd ../NYCTaxiAnalysis && mvn clean package) # Run in a subshell to return to current dir
echo "Java project build complete."
