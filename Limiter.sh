#!/bin/bash

TC=/usr/sbin/tc
IF=eth0
LIMIT=100mbit

DST_CIDR=192.168.30.0/28
#Ex: DST_CIDR=192.168.30.0/28

U32="$TC filter add dev $IF protocol ip parent 1:0 prio 1 u32"

set_throttle() {
  logger "$0: Setting Throttle"

  # create the root qdisc
  $TC qdisc add dev $IF root handle 1:0 htb \
    default 30

  # create the parent qdisc, children will borrow bandwidth from
  $TC class add dev $IF parent 1:0 classid \
    1:1 htb rate $LIMIT

  # create children qdiscs; reference parent

  # setup filters to ensure packets are enqueued to the correct
  # child based on the dst IP of the packet
  $U32 match ip dst $DST_CIDR flowid 1:1

  logger "$0: Throttle set successfully."
}

# run clean to ensure existing tc is not configured
clear_throttle() {
  logger "$0: Clear existing throttle"
  $TC qdisc del dev $IF root
}

logger "$0 initiated for $DST_CIDR"

clear_throttle
set_throttle
