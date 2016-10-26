#!/bin/bash

CLOCK_MIN=500000
CPUFREQ_GOVERNOR='interactive'
MIN_FREE_RAM=128 # MB
SWAPPINESS=1

#####################################
#
# Among tweaking VM parameters, I
# prefer to disable ZRAM since the
# CPU slows down a lot when swapping.
# The OOM killer actually does a good
# job keeping things running smoothly
# as long as one sets min RAM to a 
# higher value.
#
# Raising the min CPU freq. also
# improves responsiveness a bit
# without impacting battery life.
#
#####################################

NOD_VM='/proc/sys/vm'
#SUBSYS_MALI='/sys/class/misc/mali0/device/'

echo $CPUFREQ_GOVERNOR > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo $CLOCK_MIN       > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

# Mali @ 533MHz eats up all the thermal budget...
#echo -n off         >> $SUBSYS_MALI/dvfs
#echo -n '266000000' >> $SUBSYS_MALI/clock

echo $SWAPPINESS > $NOD_VM/swappiness
echo $(( $MIN_FREE_RAM * 1024 )) >> $NOD_VM/min_free_kbytes
swapoff /dev/zram0
