#
# Keep only records for which we have seen a callsign
# Keep message types 1, 3, 4 and 6 for aircraft who have a callsign
# Purge aircraft when they have not been heard from for inactiveSecs
#
# For details on awk associative arrays, please see:
#
# http://snap.nlc.dcccd.edu/reference/awkref/gawk_12.html
#
# Output format is: 
#
#  MSG,num,callsign,aircraft,dt,tm,lat,long,alt,gs,trk,VR,sq,emerg
#
# Input format is documented here:
#
# http://www.homepages.mcb.net/bones/SBS/Article/Barebones42_Socket_Data.htm
#
BEGIN {
	FS="," ;
	inactiveSecs = 60 ;
}

# Do this for every record
{
	if( $5 in aircraft ) {
		lastSeen = makeEpochTime( $7, $8 ) ;
		contacts[$5] = lastSeen ;  # update time last seen
	}
}

# Remember this aircraft callsign, hex id, time seen if a/c has callsign
/^MSG,1/ {
	if( $11 != "" ) {
	    if( ! ( $5 in aircraft ) ) {
	     #printf( "Just acquired aircraft id=%s\n", $11 ) > "/dev/stderr" ;
	     printf ( "+%s: %s\n", strftime( "%H%M%S", makeEpochTime( $7, $8 ) ), $11 ) > "/dev/stderr"  ;
	     nTimesSeen[$5] = 0 ;
	    }
	    aircraft[$5] = $11 ; # key is aircraft hex id, value is callsign
	    lastSeen = makeEpochTime( $7, $8 ) ; 
	    contacts[$5] = lastSeen ; # key is aircraft hex id, value is time from ADSB
	   
	    printf ( "MSG,1,%s,%s,%s,%s,%s,%s,%s\n", aircraft[$5], $5, strftime( "%Y%m%d,%H%M%S", makeEpochTime( $7, $8 ) ), latLongAlt[$5], gsTrkVR[$5], squawk[$5], emerg[$5] ) ; 
	}
	
	# Scan the aircraft array and remove any not seen for specified interval
    for ( key in aircraft  ) {
	    intervalSecs = lastSeen - contacts[key] ;
	    if ( intervalSecs > inactiveSecs ) {
		    #printf( "Removing aircraft id=%s, not seen for %d seconds, seen %d times\n", aircraft[key], intervalSecs, nTimesSeen[key] ) > "/dev/stderr" ;
		    printf ( "-%s: %s\n", strftime( "%H%M%S", makeEpochTime( $7, $8 ) ), aircraft[key] ) > "/dev/stderr" ;
		    delete contacts[key] ;
		    delete aircraft[key] ;
		    delete latLongAlt[key] ;
		    delete gsTrkVR[key] ;
		    delete squawk[key] ;
		    delete emerg[key] ;
		    delete nTimesSeen[key] ;
	    }
    }
    nTimesSeen[$5] ++ ;
	next ;
}

# Mine latitude, longitude, altitude and emerg ind from msg type 3
/^MSG,3/ {
    if( $5 in aircraft ) {
        latLongAlt[$5] = $15 "," $16 "," $12 ;
        emerg[$5] = $20 ;
        nTimesSeen[$5] ++ ;
        printf ( "MSG,3,%s,%s,%s,%s,%s,%s,%s\n", aircraft[$5], $5, strftime( "%Y%m%d,%H%M%S", makeEpochTime( $7, $8 ) ), latLongAlt[$5], gsTrkVR[$5], squawk[$5], emerg[$5] ) ; 
 
    }

    next ;
}

# Mine ground speed, track and Vertical rate from msg type 4
/^MSG,4/ {
    if( $5 in aircraft ) {
        gsTrkVR[$5] = $13 "," $14 "," $17 ;
        nTimesSeen[$5] ++ ;
        printf ( "MSG,4,%s,%s,%s,%s,%s,%s,%s\n", aircraft[$5], $5, strftime( "%Y%m%d,%H%M%S", makeEpochTime( $7, $8 ) ), latLongAlt[$5], gsTrkVR[$5], squawk[$5], emerg[$5] ) ;
    }
    
    next ;
}

# Mine altitude and squawk from msg type 6
/^MSG,6/ {
    if( $5 in aircraft ) {
        altitude[$5] = $12  ;
        squawk[$5] = $18 ;
        nTimesSeen[$5] ++ ;
        printf ( "MSG,6,%s,%s,%s,%s,%s,%s,%s\n", aircraft[$5], $5, strftime( "%Y%m%d,%H%M%S", makeEpochTime( $7, $8 ) ), latLongAlt[$5], gsTrkVR[$5], squawk[$5], emerg[$5] ) ;
    }
    next ;
}

#/(^MSG,3)|(^MSG,4)|(^MSG,6)/ {
#		printf( "%s\n", $0 ) ;
#	next ;
#}

# convert date from YYYY/MM/DD and time from HH:MM:SS to epoch
# Needed parms are dtstring and tmstring, all others are "local" variables for this
# function, per http://www.cs.utah.edu/dept/old/texinfo/gawk/gawk_14.html
function makeEpochTime( dtstring, tmstring, epochval, mon, day, yr, hour, min, sec, tmpstr ) {
	mon = substr ( dtstring, 6, 2 ) ;
	day = substr ( dtstring, 9, 2 ) ;
	yr  = substr ( dtstring, 1, 4 ) ;
	hour= substr ( tmstring, 1, 2 ) ;
	min = substr ( tmstring, 4, 2 ) ;
	sec = substr ( tmstring, 7, 2 ) ;
	tmpstr = yr " " mon " " day " " hour " " min " " sec
	#printf ( "tmpstr=%s\n", tmpstr ) ;
	epochval = mktime( tmpstr ) ;
	return epochval ;
	#return strftime( "%Y%m%d:%H%M00", epochval ) ;
}
