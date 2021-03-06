# SGD Telemetry Script
# A shell script to grab time-labeled data, archive it, 
# and upload it to the 'Ike Wai science gateway.

###---BEGIN VARIABLES---###

#Directory of the storage drive's data folder
DATADIR=~/SGDTestData #temporary directory for testing, production is /data (no tilde)

#Telemetry log location
LOG_FILE=$DATADIR/telemetry_log.txt
#Function to print info to log
LOG() { echo `date +%Y-%m-%d_%H:%M:%S`: "$@" >> $LOG_FILE; }
LOG "-----Start of run.-----"
LOG "Data directory is $DATADIR."

#Directory where we are storing the archives
ARCHIVEDIR=$DATADIR/telemetry_archive
LOG "Archive directory is $ARCHIVEDIR."

#Get the yesterday's numberical date info
YESTERDAY_YEAR=`date --date="yesterday" +%Y`
YESTERDAY_MONTH=`date --date="yesterday" +%m`
YESTERDAY_DAY=`date --date="yesterday" +%d`
LOG "Yesterday's date is $YESTERDAY_YEAR-$YESTERDAY_MONTH-$YESTERDAY_DAY."

#The data is located according to the date gathered
YESTERDAY_DATA=$DATADIR/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY

ARCHIVE_NAME="sgdsniffer_$YESTERDAY_YEAR"_"$YESTERDAY_MONTH"_"$YESTERDAY_DAY.tar.gz"

#Gateway Connection details
GATEWAY_URL='https://agaveauth.its.hawaii.edu/files/v2/media/system/ikewai-working-test/'
AUTH_TOKEN=[REDACTED] #REMOVE TOKEN BEFORE PUSHING

###---END VARIABLES---###







###---BEGIN COMMANDS---###

#Enter archive directory, create archive of yesterday's data
cd $ARCHIVEDIR
tar -zcf $ARCHIVE_NAME -C $YESTERDAY_DATA .
LOG "Archive $ARCHIVE_NAME created."

#Check if there is an active internet connection, exit if there isn't
ping -c 1 -W 10 1.1.1.1 > /dev/null 2>&1 #Sends one packet to cloudflare, waits up to 10 seconds for response.
if [ $? -eq 0 ]
then
    NOCONNECTION=0;
    LOG "Internet connection seems to work. Will attempt to upload now."
else
    LOG "No internet connection. Will attempt to upload tomorrow."
    exit 0
fi


#Primary uploading loop

#Get amount of files in the directory
ARCHIVES=`ls -1 | wc -l`

#While there are still archives to upload, send them and delete the files
#upon confirmation of successful upload
INDEX=0;
LOG "Will attempt to upload $ARCHIVES archive(s)."
while [ $INDEX -lt $ARCHIVES ]
do
    #Get archive path (we're in ARCHIVEDIR)
    ARCHIVE_TO_UPLOAD=`ls -1 | head -1` #Gets list of files in single column, then grabs the first item
    LOG "Will now begin uploading $ARCHIVE_TO_UPLOAD."
    
    #Upload the archive
    curl -sk -H "Authorization: Bearer $AUTH_TOKEN"\
    -X POST \
    -F "fileToUpload=@$ARCHIVE_TO_UPLOAD"\
    "$GATEWAY_URL"\
    >> gateway_response.json
    if [ $? -eq 0 ]
    then
        LOG "Uploaded $ARCHIVE_TO_UPLOAD."
    else
        LOG "Upload failed."
    fi
    
    #Make sure the archive was correctly received
    python gateway_response_parser.py
    GATEWAY_RESPONSE=$? # 0 means intact, 1 means error
    
    #If the upload was received, delete the offline copy
    if [ $GATEWAY_RESPONSE -eq 0 ]
    then
        LOG "Confirmed $ARCHIVE_TO_UPLOAD is intact on remote."
        rm $ARCHIVE_TO_UPLOAD
        LOG "Deleted $ARCHIVE_TO_UPLOAD from local."
    else
        LOG "Couldn't confirm $ARCHIVE_TO_UPLOAD is intact on remote. Not deleting."
    fi
    ((INDEX++))
done


LOG "-----End of run.-----"
echo ""
exit 0;
###---END COMMANDS---###

EOF