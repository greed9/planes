all:
	gcc -o alt_dist_bearing alt_dist_bearing2.c  `pkg-config --cflags --libs` -lm -O2
