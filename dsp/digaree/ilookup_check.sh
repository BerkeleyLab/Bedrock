# Checks that the lookup table results from sf_main.v and sim1.c match
paste inverse.out inverse.dat | awk 'BEGIN{f=0}{if ($1 != $3) f=1; if ($2 != $4) {print $0; f=1}}END{if (f) print "FAIL"; else print "PASS"; exit(f)}'
