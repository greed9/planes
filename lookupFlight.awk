# 
# Lookup flight on flighttraker (quietly, we know how they feel about 'bots)
#
BEGIN {
}

{
    if ( $1 == "targetedAirCity" ) {
	destCity = cleanValues( $0 ) ;
    } else if ( $1 == "targetedDepCity" ) {
	departureCity = cleanValues( $0 ) ;
    } else if ( $1 == "targetedDepartureAirport" ) {
	departureAirport = cleanValues( $0 ) ;
    } else if ( $1 == "targetedArrivalAirport" ) {
	arrivalAirport = cleanValues( $0 ) ;
    }
}

END {
    printf ( "from %s (%s), to %s (%s)\n", departureCity, departureAirport, destCity, arrivalAirport  ) ;
}

function cleanValues( inStr, tmp ) {
        split ( inStr, arr, "=" ) ;
        tmp = arr[2] ;
        gsub ( /"/, "", tmp ) ;
        gsub ( / /, "", tmp ) ;
        gsub ( /;/, "", tmp ) ;
	return tmp ;
}

