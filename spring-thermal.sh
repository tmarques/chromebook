#!/bin/bash

MAX_FREQ_BAT=1600000
MAX_FREQ_ACP=1700000
TEMP_TARGET=75

NOD_SUBSYS='/sys/devices/system/cpu/cpu0/cpufreq/'
NOD_FREQMIN=$NOD_SUBSYS'/scaling_min_freq'
NOD_FREQMAX=$NOD_SUBSYS'/scaling_max_freq'
NOD_FREQ0=$NOD_SUBSYS'/scaling_cur_freq'
NOD_FREQS=$NOD_SUBSYS'/scaling_available_frequencies';
NOD_PS='/sys/class/power_supply/cros-ec-charger/online'
NOD_TEMP='/sys/class/thermal/thermal_zone0/temp'

FREQS=`cat $NOD_FREQS`

function work {
  tput cup 0 0;

  # Dynamic limited frequency
  FREQT=`cat $NOD_FREQMAX`
  FREQO=$FREQT;
  FREQ0=`cat $NOD_FREQ0`
  FREQ_UP=0;

  if [ `cat $NOD_PS` -eq 0 ]; then
    MAX_FREQ=$MAX_FREQ_BAT;
  else
    MAX_FREQ=$MAX_FREQ_ACP;
  fi;

  TEMP=`cat $NOD_TEMP`
  let TEMP=TEMP/1000

  if [ $TEMP -gt $TEMP_TARGET ]; then
    for FREQ in $FREQS; do
      if [ $FREQ -lt $FREQT ]; then
        FREQT=$FREQ
        break
      fi;
    done
  else
    if [ $FREQO -lt $MAX_FREQ ]; then
      FREQ_UP=1
    fi;
  fi

  # Don't want to clock up if we're already very
  # close to TEMP_TARGET.
  if [ $TEMP -gt $(( $TEMP_TARGET-2 )) ]; then
    FREQ_UP=0;
  fi

  if [ $FREQ_UP -eq 1 ]; then
    FREQS_TMP=( $FREQS )
    let I=${#FREQS_TMP[@]}-1

    while [ $I -ge 0 ]; do
      if [ ${FREQS_TMP[I]} -gt $FREQT ]; then
        FREQT=${FREQS_TMP[I]}
        break
      fi;

      let I=I-1
    done
  fi

  if [ $FREQT -gt $MAX_FREQ ]; then
    FREQT=$MAX_FREQ;
  fi;

  # This is only allowed in really bad spots, because we kind of
  # actually want a minimally responsive system.
  if [ $FREQT -lt `cat $NOD_FREQMIN` ]; then
    echo -n $FREQT >> $NOD_FREQMIN;
  fi

  if [ $FREQO -ne $FREQT ]; then
    echo -n $FREQT >> $NOD_FREQMAX;
    if [ $FREQ_UP -eq 1 ]; then
      echo ${FREQT} >> /tmp/cpufreq.log
    else
      echo "        ${FREQT}" >> /tmp/cpufreq.log
    fi;
  fi;

  let FREQ0=FREQ0/1000
  let FREQT=FREQT/1000

  printf "%4d/%4dMHz - %dC\n\n" ${FREQ0} ${FREQT} ${TEMP}

  free -m
  printf '\n'
  ectool powerinfo 2> /dev/null

}

tput clear;
 
while [ 1 ]; do
  work;
  sleep 1;
done
