# Read the HTML from ask.com and parse out ICAO airline codes and 
# corresponding names
#
#  http://www.ask.com/wiki/Airline_codes-All?qsrc=3044
#
BEGIN {
	state = 0 ;
	FS = "\"" ;
	printf ( "BEGIN {\n" ) ;
}

/^<tr>/ {
	state = 1 ;
	next ;
}

/^<\/tr>/ {
	state = 0 ;
}

/^<td>[A-Z][A-Z][A-Z]<\/td>/ {
	#print substr( $0, 5, 3 )  ;
	key =  substr( $0, 5, 3 ) ;
	next ;
}

/^(<td><a)|(<td><i><a)/ {\
	if( state == 1 ) {
		#print $4 ;
		printf ( "\tarr[%s]=\"%s\";\n", key, $4 ) ;
	}
	next  ;
}

END {
	printf ("}\n" ) ;
}
