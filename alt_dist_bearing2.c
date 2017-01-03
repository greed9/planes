    
    // http://cosinekitty.com/compass.html
    
    #include <math.h>
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    
    typedef struct 
    {
        double lat ;
        double lon ;
        double elv ;
    } Location ;
    
    typedef struct 
    {
        double x ;
        double y ;
        double z ;
        double radius ;
    } Coords ;
    
double feetToMeters ( double feet )
{
	return feet / 3.2808 ;
}

double kmToMiles ( double km ) 
{
	return km * 0.62137 ;
}

void printLocation ( Location pL )
{
	//printf ( "debug:lat=%lf, long=%lf, elv=%lf\n",
	//	pL.lat, pL.lon, pL.elv ) ;
}

void printPoint ( Coords pP )
{
	//printf ( "debug:x=%lf, y=%lf, z=%lf, radius=%lf\n",
	//	pP.x, pP.y, pP.z, pP.radius ) ;
}

    double EarthRadiusInMeters ( double latitudeRadians)
    {
        // http://en.wikipedia.org/wiki/Earth_radius
        double a = 6378137.0;  // equatorial radius in meters
        double b = 6356752.3;  // polar radius in meters
        double cosx = cos (latitudeRadians);
        double sinx = sin (latitudeRadians);
        double t1 = a * a * cosx;
        double t2 = b * b * sinx;
        double t3 = a * cosx;
        double t4 = b * sinx;
        return sqrt ((t1*t1 + t2*t2) / (t3*t3 + t4*t4));
    }

    Coords LocationToPoint (Location c )
    {
        // Convert (lat, lon, elv) to (x, y, z).
        Coords retCoord ;
        
        double lat = c.lat * M_PI / 180.0;
        double lon = c.lon * M_PI / 180.0;
        retCoord.radius = c.elv + EarthRadiusInMeters (lat);
        double cosLon = cos (lon);
        double sinLon = sin (lon);
        double cosLat = cos (lat);
        double sinLat = sin (lat);
        retCoord.x = cosLon * cosLat * retCoord.radius;
        retCoord.y = sinLon * cosLat * retCoord.radius;
        retCoord.z = sinLat * retCoord.radius;
        return retCoord ;
    }

    double Distance ( Coords ap, Coords bp )
    {
        double dx = ap.x - bp.x;
        double dy = ap.y - bp.y;
        double dz = ap.z - bp.z;
        return sqrt (dx*dx + dy*dy + dz*dz);
    }
    

    Coords RotateGlobe (Location b, Location a, double bradius, double aradius)
    {
        // Get modified coordinates of 'b' by rotating the globe so that 'a' is at lat=0, lon=0.
        Location br ;
        Coords retCoord ;
        
        br.lat = b.lat ;
        br.lon = b.lon - a.lon ;
        br.elv = b.elv ;
        
        Coords brp = LocationToPoint ( br );

        // scale all the coordinates based on the original, correct geoid radius...
        brp.x *= (bradius / brp.radius);
        brp.y *= (bradius / brp.radius);
        brp.z *= (bradius / brp.radius);
        brp.radius = bradius;   // restore actual geoid-based radius calculation

        // Rotate brp cartesian coordinates around the z-axis by a.lon degrees,
        // then around the y-axis by a.lat degrees.
        // Though we are decreasing by a.lat degrees, as seen above the y-axis,
        // this is a positive (counterclockwise) rotation (if B's longitude is east of A's).
        // However, from this point of view the x-axis is pointing left.
        // So we will look the other way making the x-axis pointing right, the z-axis
        // pointing up, and the rotation treated as negative.

        double alat = -a.lat * M_PI / 180.0;
        double acos = cos (alat);
        double asin = sin (alat);

        retCoord.x = (brp.x * acos) - (brp.z * asin);
        retCoord.y = brp.y;
        retCoord.z = (brp.x * asin) + (brp.z * acos);

        return retCoord ;
    }
   
   double ParseAngle ( char* id, double limit )
    {
        double angle = atof ( id );
	
	// debug
	//printf ( "debug: id=%s\n", id ) ;
	//printf ( "debug: angle=%lf\n", angle ) ;
	// end debug

        if (angle == 0.0 || (angle < -limit) || (angle > limit)) {
            return 0.0;
        } else {
            return angle;
        }
    }

    double ParseElevation ( char* id )
    {
        double angle = atof ( id );
        if ( angle == 0.0 ) {
            return 0.0 ;
        } else {
            return angle;
        }
    }

    Location ParseLocation ( char* latStr, char* lonStr, double elvVal )
    {
        double lat = ParseAngle ( latStr, 90.0);
        Location location ;
        if ( lat != 0.0 ) {
            double lon = ParseAngle ( lonStr, 180.0);
            if (lon != 0.0 ) {
                double elv = elvVal ;
                if (elv != 0.0 ) {
                    location.lat = lat ;
                    location.lon = lon ;
                    location.elv = elv ;
                }
            }
        }
        return location;
    }
   
    double Calculate( char* latStr1, char* lonStr1, char* elvStr1, char* latStr2, char* lonStr2, char* elvStr2 )
    {
        Location a = ParseLocation ( latStr1, lonStr1, feetToMeters ( atof ( elvStr1 ) ) ) ;
        Location b = ParseLocation ( latStr2, lonStr2, feetToMeters ( atof ( elvStr2 ) ) ) ;
           
	// debug
	printLocation ( a ) ;
	printLocation ( b ) ;
	// end debug

        Coords ap = LocationToPoint (a);
        Coords bp = LocationToPoint (b);
        double distKm = 0.001 * round( Distance (ap, bp) );
        printf ( "dist(mi)=%lf,", kmToMiles ( distKm ) ) ;

        // Let's use a trick to calculate azimuth:
        // Rotate the globe so that point A looks like latitude 0, longitude 0.
        // We keep the actual radii calculated based on the oblate geoid,
        // but use angles based on subtraction.
        // Point A will be at x=radius, y=0, z=0.
        // Vector difference B-A will have dz = N/S component, dy = E/W component.

        Coords br = RotateGlobe (b, a, bp.radius, ap.radius);
        double theta = atan2 (br.z, br.y) * 180.0 / M_PI;
        double azimuth = 90.0 - theta;
        if (azimuth < 0.0) {
            azimuth += 360.0;
        }
        if (azimuth > 360.0) {
            azimuth -= 360.0;
        }
        printf ( "azimuth=%lf,", (round(azimuth*10)/10) ) ;
        
       // $('div_Azimuth').innerHTML = (Math.round(azimuth*10)/10) + '&deg;';

        // Calculate altitude, which is the angle above the horizon of B as seen from A.
        // Almost always, B will actually be below the horizon, so the altitude will be negative.
        double shadow = sqrt ((br.y * br.y) + (br.z * br.z));
        double altitude = atan2 (br.x - ap.radius, shadow) * 180.0 / M_PI;
        printf ( "elevation=%lf\n", (round(altitude*100)/100) ) ;
        //$('div_Altitude').innerHTML = (Math.round(altitude*100)/100).toString().replace(/-/g,'&minus;') + '&deg;';
    }
    
// Split str into tokens using delim, populate tokens array, return number of tokens
// Tokens array must be pre-allocated and appropriately sized. (e.g. at least maxTokens elements)
// Since str is modified  by strtok, it must be mutable (not a constant).
int split ( char* tokens[ ], char* str, char* delim )
{
	int i = 0 ;
	int maxTokens = 20 ;
	char* ptr = strtok ( str, delim ) ;
	while ( ptr && *ptr && ( i < maxTokens ) )
	{
		//printf ( "debug: tok=%s\n", ptr ) ;
		tokens[i] = ptr ;
		i++ ;
		ptr = strtok ( 0, delim ) ;
	}
	return i ;
}

    int main ( int argc, char* argv[] )
    {
        //Calculate ("28.689063", "-81.51522", "100",
        //    "28.53973", "-81.32699", "30000" ) ;
        int i ;
	char* tokens[50] = { 0 } ;
	char record[2000] = { '\0' } ;
	char* homeLat = 0 ;
	char* homeLon = 0 ;
	char* homeElv = 0 ;

	// Check args
	if ( argc < 4 )
	{
		fprintf ( stderr, "%s: usage: %s lat long evl\n", argv[0], argv[0] ) ;
		return 1 ;
	}
	
	// Location of our site
	homeLat = argv[1] ;
	homeLon = argv[2] ;
	homeElv = argv[3] ;

	fgets ( record, sizeof ( record ) - 1, stdin ) ;
	while ( !feof ( stdin ) && !ferror ( stdin ) ) 
	{
		// Read some stuff? If so, split it
		i = split ( tokens, record, "," ) ;

		// If more than 0 tokens and second field is 3
		if ( i 
		    && tokens[2]
		    && tokens[5]
		    && tokens[4]
		    && tokens[9]
		    && tokens[10]
		    && tokens[8]
		    && tokens[6] 
		    && strlen ( tokens[6] ) > 0 
		    && 
		    ( 
		        strcmp( tokens[1], "3" ) == 0 
		        || strcmp( tokens[1], "4" ) == 0 ) 
		    )
		{
			fprintf ( stdout, "flt=%s,time=%s,date=%s,speed=%s,heading=%s,altitude=%s,", 
			    tokens[2],
			    tokens[5],
			    tokens[4],
			    tokens[9],
			    tokens[10],
			    tokens[8]
			) ;
			Calculate ( homeLat, homeLon, homeElv, tokens[6], tokens[7], tokens[8] ) ;
		}
		fgets ( record, sizeof ( record ) - 1, stdin ) ;
		memset ( tokens, '\0', sizeof ( tokens ) ) ;
	}

/*
	strcpy ( record, "28.689063,-81.51522,100" ) ;
	int nToks = split ( tokens, record, "," ) ;
	printf ( "nToks=%d\n", nToks ) ;
	for ( i = 0 ; i < nToks ; i++ )
	{
		printf ( "tokens[%i]=%s\n", i, tokens[i] ) ;
	}
*/
        return 0 ;
    }
    
