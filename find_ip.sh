#!/bin/bash -e
aws ec2 describe-instances --filters "Name=tag:Name,Values=yakaas-metrics" | grep "PrivateIpAddress" | head -1 | awk '{split($0, a, "\""); print a[4]}'
