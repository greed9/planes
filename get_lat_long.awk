# gpspipe -w | grep TPV | awk 'BEGIN{FS=","}{print $7 ":" $8}' | awk 'BEGIN{FS=":"}{print $1}'
BEGIN {
	FS=","
}
/TPV/{
	split( $7, a, ":" )
	split( $8, b, ":" )
	print ( a[2] " " b[2] )
	#print $7 "," $8
	fflush( stdout )
}

