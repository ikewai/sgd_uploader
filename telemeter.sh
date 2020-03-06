#!/bin/bash
#This script handles communication with the telemetry module.
 
#Set up serial port for telemetry
eval $(xuartctl --server --port=1 --mode=8n1 --speed=9600 2>&1); ln -s $ttyname /dev/ttycom3
 
 
 
#Determine what the most recent data file should be
DATADIR=/data
 
LOG_FILE=$DATADIR/telemetry_log.txt
LOG() { echo `date +%Y-%m-%d_%H:%M:%S`: "$@" >> $LOG_FILE; }
LOG "---Start of telemetry process.---"
LOG "Data Directory is $DATADIR."
 
#Determine and navigate to the previous day's data directory
YESTERDAY_YEAR=`date="yesterday" +%Y`
YESTERDAY_MONTH=`date="yesterday" +%m`
YESTERDAY_DAY=`date="yesterday" +%d`
LOG "Yesterday's date is $YESTERDAY_YEAR Y $YESTERDAY_MONTH M $YESTERDAY_DAY D."
 
YESTERDAY_DATA=$DATADIR/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY
 
cd $YESTERDAY_DATA
if [ $? -eq 1 ] #if the directory doesn't exist (eg. no data yet)
then
  exit 1        #exit the script.
fi
 
#Check if this is the first time the script has successfully run today.
#If so, send the data. If not, exit (and try again next startup)
 
CURRENT_DAY=`date +%d`
 
#Make a file to store the day, if it doesn't exist already.
cat $DATADIR/tel_previous_day > /dev/null
if [ $? -eq 1 ]
then
  echo $CURRENT_DAY > $DATADIR/tel_previous_day
fi
 
#Get the day of the month that the upload was done last
LAST_TELEMETRY_RUN=`sed -n 1p $DATADIR/tel_previous_day`
 
#If it's still the same day, cleanly exit
if [ $LAST_TELEMETRY_RUN -eq $CURRENT_DAY ]
then
  exit 0
fi
 
 
 
#Get amount of files in the directory
FILE_COUNT=`ls -1 | wc -l`
 
#While there are still files to send data from,
#pull the data and send it to ttycom3
INDEX=0
LOG "Attempting to send $FILE_COUNT lines of data."
 
while [ $INDEX -lt $FILE_COUNT ]
do
  #get current file name from the index-th result of an ls.
  CURRENT_FILE=`ls -1 | sed -n "$INDEX"p`
 
  #send line 3 of the file to the serial port.
  sed -n 3p $CURRENT_FILE >> /dev/ttycom3
 
  ((INDEX++))
done
 
 
rm $DATADIR/tel_previous_day
echo $CURRENT_DAY > $DATADIR/tel_previous_day
 
exit 0
EOF
