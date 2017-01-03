#!/bin/bash
nc 192.168.1.50 30003 | gawk -f callSign.awk | ./alt_dist_bearing 28.689063 -81.51522 100 | gawk -f inRange.awk
