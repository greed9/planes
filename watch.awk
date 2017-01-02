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
# http://travel.flightexplorer.com/FlightTracker/DAL105
#
# grep DAL105 dal105.out | gawk 'BEGIN{ FS=">" ; } { print $7 " " $11 " " $20}'
#
BEGIN {
    FS = "," ;
    ua = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:21.0) Gecko/20130331 Firefox/21.0" ;
    #curlCmd = "curl --silent --user-agent " "\"" ua "\"" " http://www.flightstats.com/go/FlightStatus/flightStatusByFlight.do?flightNumber=" ;
    curlCmd = "curl --silent --user-agent " "\"" ua "\"" " http://travel.flightexplorer.com/FlightTracker/" ;
    airportCurlCmd = "curl --silent --user-agent " "\"" ua "\"" " http://travel.flightexplorer.com/" ;
	
    # Home, looking east
    maxDist = 12.0 ;
    minElv = 5.0 ;
    minAz = 0.0 ;
    maxAz = 180.0 ;

    # Valencia visibility, looking East
    maxDist = 12.0 ;
    minElv = 5.0 ;
    minAz = 0.0 ;
    maxAz = 180.0 ;
}

{
    flt = $1 ;
    flt = cleanValues( flt ) ;

    dist = $7 ;
    split ( dist,  arr, "=" ) ;
    dist = arr[2] ;
    
    az = $8 ;
    split ( az, arr, "=" ) ;
    az = arr[2] ;
    
    elv = $9 ;
    split ( elv, arr, "=" ) ;
    elv = arr[2] ;
    
    #printf ( "dist=%s, az=%s, elv=%s\n", dist, az, elv ) ;
    
    # See if it is in view
    if ( dist < maxDist  && elv > minElv && az > minAz && az < maxAz ) {
        #printf ( "dist=%s, az=%s, elv=%s\n", dist, az, elv ) ;

	    # get the current time
	    tmNow = makeEpochTime( cleanValues( $3 ), cleanValues( $2 ) ) ;

	    # if we have seen this flight before
	    if ( flt in visibleTm ) {
		    interval = tmNow - visibleTm[flt] ;

		    # print every 30 secs
		    if( ( interval % 30 ) == 0 ) {
		        parseFlight( $0, info ) ;
		        look = determineDirection( info["azimuth"] ) ;
		        heading = determineDirection( info["heading"] ) ;
		        high = determineHeight( info["elevation"] ) ;
				alt = info["altitude"] ;
				speed = info["speed"] ;
		        # Looking <elevation> to the <direction> I see <flight>, at <altitude>, 
				# heading <heading>, at <speed> kts. 
		        printf ( "Looking %s to the %s I see %s, at %s, heading %s at %s kts.\n",  high, look, info["flt"], alt, heading, speed ) ;
			    #print $0 ;
		    }

		    # track the max elevation for this pass
		    if( elv > maxElev[flt] ) {
			    maxElev[flt] = elv ;
		    }
        } else {
		    # first time in view
		    #flt = cleanValues( $1 ) ;
		    visibleTm[flt] = tmNow ;
		    maxElev[flt] = elv ;
		    flightInfo[flt] = lookupFlight2( flt, curlCmd ) ;
			print "flt=" flt
			split ( flightInfo[flt], arr, "/" ) ;
			fromAirportCode = arr[1] ;
			fromAirportInfo = lookupAirport( fromAirportCode, airportCurlCmd ) ;
			toAirportCode = arr[2] ;
			toAirportInfo = lookupAirport( toAirportCode, airportCurlCmd ) ;
			parseFlight( $0, info ) ;
			if( fromAirportInfo != "" && toAirportInfo != "" ) {
				printf ( "Here comes %s, from %s (%s) to %s (%s)\n", info["flt"], fromAirportCode, fromAirportInfo, toAirportCode, toAirportInfo ) ;
			}
		    #printf ( "%s %s -> %s:\n%s", flightInfo[flt], fromAirportInfo, toAirportInfo, $0 ) ;
	    }

        	
	    fflush ( "/dev/stdout" ) ;
    } else {

	    # Just flew out of view
	    if ( flt in visibleTm ) {
		    tmEnd = makeEpochTime( cleanValues( $3 ), cleanValues( $2 ) ) ;
		    printf ( "Flight=%s,visible(secs)=%s,maxElv=%s\n", flt, tmEnd - visibleTm[flt], maxElev[flt] ) ;
		    delete visibleTm[flt] ;
		    delete maxElev[flt] ;
		    delete flightInfo[flt] ;
			fflush ( "/dev/stdout" ) ;
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

# Get flight origin/dest info
#
# Per:
#	http://www.gnu.org/software/gawk/manual/html_node/Two_002dway-I_002fO.html#Two_002dway-I_002fO
#
function lookupFlight( flight, cmd, line, shCmd, destCity, departureCity, departureAirport, arrivalAirport, nLines, nToks, status, prev ) {
	cmd = cmd flight ;
	shCmd = "/bin/sh" ;
	#print "cmd=" "\"" cmd "\"" ;
	nLines = 0 ;
	destCity = "Unknown" ;
	departureCity = "Unknown" ;
	departureAirport = "Unknown" ;
	arrivalAirport = "Unknown" ;
	status = "Unknown" ;
	print cmd |& shCmd ;
	close ( shCmd, "to" ) ;
	while (( shCmd |& getline line) > 0) {
		if ( match ( line, "</title>" ) ) {
			#printf ( "prev=\"%s\"\n", prev ) ;
			if( length( prev ) > 0 && match( prev, "<head>" ) == 0 ) {
				status = prev ;
			}
		}
		nToks = split ( line, arr, " " ) ;
		if( nToks > 1 ) {
 			if ( arr[1] == "targetedAirCity" ) {
				destCity = cleanValues( line ) ;
    			} else if ( arr[1] == "targetedDepCity" && nToks == 3 ) {
				departureCity = cleanValues( line ) ;
    			} else if ( arr[1] == "targetedDepartureAirport" ) {
				departureAirport = cleanValues( line ) ;
    			} else if ( arr[1] == "targetedArrivalAirport" ) {
				arrivalAirport = cleanValues( line ) ;
    			}
		}
		nLines ++ ;
		prev = line ;

	}
        close( shCmd ) ;
	#print "nLines=" nLines ;
	return status " from " departureCity " (" departureAirport "), to "  destCity " (" arrivalAirport ")" ;
}

# Get flight origin/dest info
# using http://travel.flightexplorer.com/FlightTracker/
#
# Per:
#	http://www.gnu.org/software/gawk/manual/html_node/Two_002dway-I_002fO.html#Two_002dway-I_002fO
#
function lookupFlight2( flight, cmd, line, shCmd, departureAirport, arrivalAirport, nLines, status, toks, done ) {
	cmd = cmd flight ;
	shCmd = "/bin/sh" ;
	#print "cmd=" "\"" cmd "\"" ;
	nLines = 0 ;
	
	departureAirport = "Unknown" ;
	arrivalAirport = "Unknown" ;
	status = "Unknown" ;
	done = 0 ;
	print cmd |& shCmd ;
	close ( shCmd, "to" ) ;
	while (( shCmd |& getline line) > 0 && !done ) {
	
	    # find the flight status, then parse it.
		if ( match ( line, flight ) ) {
		    # print "line=" line ;
		    # Strip off all the html tags and get to, from and status
			status = cleanFlightStatus( line, tmp ) ;
			#print "status=" status ;
			if( match( status, "In Flight" ) ) {
				split ( status, toks, "," ) ;
				gsub( " ", "", toks[1] ) ;
				departureAirport = toks[1] ;
				gsub( " ", "", toks[2] ) ;
				arrivalAirport = toks[2] ;
				done = 1 ;
			}
		}
		
		nLines ++ ;

	}
    close( shCmd ) ;
	#print "nLines=" nLines ;
	return  departureAirport "/"  arrivalAirport ;
}

# Get airport name and city
# using http://travel.flightexplorer.com/MCO
#
# Per:
#	http://www.gnu.org/software/gawk/manual/html_node/Two_002dway-I_002fO.html#Two_002dway-I_002fO
#
function lookupAirport( airportCode, cmd, line, shCmd, nLines, airport, city, toks, result ) {
	cmd = cmd airportCode ;
	shCmd = "/bin/sh" ;
	#print "cmd=" "\"" cmd "\"" ;
	nLines = 0 ;
	done = 0 ;
	
	print cmd |& shCmd ;
	close ( shCmd, "to" ) ;
	while (( shCmd |& getline line) > 0 && !done ) {
	
	    # find the airport info, then parse it.
		if ( match ( line, "Name:" ) && !done ) {
			split ( line, toks, "td" ) ;
			gsub( />|<|\//, "", toks[4] ) ;
			airport = toks[4] ;
			gsub( />|<|\//, "", toks[8] ) ;
			city = toks[8] ;
			done = 1 ;
		}
		
		nLines ++ ;

	}
    	close( shCmd ) ;
	#print "airport=" airport ;
	#print "city=" city ;
	return  airport "(" city ")" ;
}

# Clean up the flight status returned from:
# 
# http://travel.flightexplorer.com/FlightTracker/
#
function cleanFlightStatus( line, tmp ) {
    split( line, tmp, ">" ) ;
    gsub( "</a", "", tmp[7] ) ;
    gsub( "</a", "", tmp[11] ) ;
    gsub( "</a", "", tmp[20] ) ;
    
    gsub( "<td", "", tmp[7] ) ;
    gsub( "</td", "", tmp[11] ) ;
    gsub( "</td", "", tmp[20] ) ;
    
    return tmp[7] "," tmp[11] "," tmp[20] ;
    
}

function parseFlight( inStr, fltArr, tmpArr, tmpArr2, i ) {
    # First take the line apart on commas
    split( inStr, tmpArr, "," ) ;
    
    # Now split each array element on the equals sign
    # left side is key (index) right side is value
    for( i in tmpArr ) {
        split( tmpArr[i], tmpArr2, "=" ) ;
        fltArr[tmpArr[1]] = tmpArr2[2] ;
    }
    
    return ;
}

function determineDirection( x, dir ) {
    if ( x >= 338 || x < 23 ) {
		dir = "N" ;
	}
	else if ( x >= 23 && x < 68 ) {
		dir = "NE" ;
	}
	else if ( x >= 68 && x < 113 ) {
		dir = "E" ;
	}
	else if ( x >= 113 && x < 157 ) {
		dir = "SE" ;
	}
	else if ( x >= 157 && x < 202 ) {
		dir = "S" ;
	}
	else if ( x >= 202 && x < 247 ) {
		dir = "SW" ;
	}
	else if ( x >= 247 && x < 293 ) {
		dir = "W" ;
	}
	else if ( x >= 293 && x < 338 ) {
		dir = "NW" ;
	}
	return dir
}

function determineHeight( x, high ) {
	if ( x < 10 ) {
		high = "low" ;
	} else if ( x < 20 ) {
		high = "halfway up" ;
	} else if ( x < 30 ) {
		high = "high" l
	} else {
		high = "overhead" ;
	}
	return high ;
}
 
