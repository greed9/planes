#
# Find aircraft in range
#
# tail -f /mnt/sdc1/20130719_adsb.out | gawk -f  callsign.awk | tee -a /mnt/sdc1/adsb_filtered.out | ./alt_dist_bearing 28.689063 -81.51522 100
# | gawk -f inRange.awk
#
# curl --user-agent "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:21.0) Gecko/20130331 Firefox/21.0" http://www.flightstats.com/go/FlightStatus/flightStatusByFlight.do?flightNumber=NKS863 | grep targeted
#
# Input format is:
#
# flt=UAL1207 ,time=130933,date=20130731,speed=207,heading=74,altitude=4050,dist(mi)=8.163559,azimuth=28.700000,elevation=5.070000
#
BEGIN {
    FS = "," ;
    ua = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:21.0) Gecko/20130331 Firefox/21.0" ;
    maxDist = 12.0 ;
    minElv = 5.0 ;
    minAz = 0.0 ;
    maxAz = 360.0 ;
}

{
    flt = $1 ;
    split( flt, arr, "=" ) ;
    flt = arr[2] ;
    
    dist = $7 ;
    split ( dist,  arr, "=" ) ;
    dist = arr[2] ;
    
    az = $8 ;
    split ( az, arr, "=" ) ;
    az = arr[2] ;
    
    elv = $9 ;
    split ( elv, arr, "=" ) ;
    elv = arr[2] ;
    
    bearing = $5 ;
    split( bearing, arr, "=" ) ;
    bearing = arr[2] ;
    
    #printf ( "dist=%s, az=%s, elv=%s\n", dist, az, elv ) ;
    
    # See if it is in view
    if ( dist < maxDist  && elv > minElv && az > minAz && az < maxAz ) {
        #printf ( "dist=%s, az=%s, elv=%s\n", dist, az, elv ) ;

	# get the current time
	tmNow = makeEpochTime( cleanValues( $3 ), cleanValues( $2 ) ) ;

	# if we have seen this flight before
	if ( flt in visibleTm ) {
		interval = tmNow - visibleTm[flt] ;

		# print every 10 secs
		if( ( interval % 10 ) == 0 ) {
			#print $0 ;
			printf( "*Flight: %s, Az: %s, El: %s, Heading: %s, Dist: %s\n", flt, az, elv, bearing, dist ) ;
		}

		# track the max elevation for this pass
		if( elv > maxElev[flt] ) {
			maxElev[flt] = elv ;
		}
    	} else {
		# first time in view
		visibleTm[flt] = tmNow ;
		maxElev[flt] = elv ;
		#flightInfo[flt] = lookupFlight( cleanvalues( $1 ) ) ;
		#print $0 ;
		printf( "+Flight: %s, Az: %s, El: %s, Heading: %s, Dist: %s\n", flt, az, elv, bearing, dist ) ;
	}

        	
	fflush ( "/dev/stdout" ) ;
    } else {

	# Just flew out of view
	if ( flt in visibleTm ) {
		tmEnd = makeEpochTime( cleanValues( $3 ), cleanValues( $2 ) ) ;
		#printf ( "Flight=%s,visible(secs)=%s,maxElv=%s\n", flt, tmEnd - visibleTm[flt], maxElev[flt] ) ;
		printf ( "-Flight: %s, Secs: %s, El: %s\n", flt, tmEnd - visibleTm[flt], maxElev[flt] ) ;
		delete visibleTm[flt] ;
		delete maxElev[flt] ;
		#delete flightInfo[flt] ;
	}
        next ;
    }
}

# convert date from YYYYMMDD and time from HHMMSS to epoch
# Needed parms are dtstring and tmstring, all others are "local" variables for this
# function, per http://www.cs.utah.edu/dept/old/texinfo/gawk/gawk_14.html
function makeEpochTime( dtstring, tmstring, epochval, mon, day, yr, hour, min, sec, tmpstr ) {
	mon = substr ( dtstring, 5, 2 ) ;
	day = substr ( dtstring, 7, 2 ) ;
	yr  = substr ( dtstring, 1, 4 ) ;
	hour= substr ( tmstring, 1, 2 ) ;
	min = substr ( tmstring, 3, 2 ) ;
	sec = substr ( tmstring, 5, 2 ) ;
	tmpstr = yr " " mon " " day " " hour " " min " " sec
	#printf ( "tmpstr=%s\n", tmpstr ) ;
	epochval = mktime( tmpstr ) ;
	return epochval ;
	#return strftime( "%Y%m%d:%H%M00", epochval ) ;
}

# Strip off the keyword and the =, from input token
function cleanValues( inStr, tmp ) {
        split ( inStr, arr, "=" ) ;
        tmp = arr[2] ;
        gsub ( /"/, "", tmp ) ;
        gsub ( / /, "", tmp ) ;
        gsub ( /;/, "", tmp ) ;
	return tmp ;
}

