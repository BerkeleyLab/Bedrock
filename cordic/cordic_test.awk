# cordic_test.awk
# Larry Doolittle, LBNL

BEGIN{
  # fs=16384*1.64676
  scale=1.64676
}
/^xxx width/{width=$3; isc=2^width;}
!/x/{
  if ($7==0) {
    a  = $1/isc*3.1415926
    xv = ($2*cos(a)-$3*sin(a))*scale
    yv = ($2*sin(a)+$3*cos(a))*scale
    # printf "%s : %9.2f %9.2f\n", $0, xv, yv
    e = $4-xv
  } else if ($7==1) {
    a2 = atan2($3,$2)*isc/3.1415926
    if (a2<0) a2=a2+2*isc;
    e  = $6 - a2
    # printf "%s : %9.2f %5.2f\n", $0, a2, e
  } else if ($7==3) {
    # assume $3 == 0
    gx = $2*scale*cos(a2*3.1415926/isc)
    gy = $2*scale*sin(a2*3.1415926/isc)
    # print gx,$4,gy,$5
    e = $4-gx
  }
  if (e>emax) emax=e
  if (e<emin) emin=e
  e2sum = e2sum + e*e
  n = n+1
  if ($7==0) {
    e = $5-yv
    if (e>emax) emax=e
    if (e<emin) emin=e
    e2sum = e2sum + e*e
    n = n+1
  }
  if ($7==3) {
    e = $5-gy
    if (e>emax) emax=e
    if (e<emin) emin=e
    e2sum = e2sum + e*e
    n = n+1
  }
  r = sqrt($4*$4+$5*$5);
  if (r>maxamp) maxamp=r
}
END{
  printf "test covers %d points, maximum amplitude is %d counts\n", n, maxamp
  if (-emin > emax) emax=-emin
  rms=sqrt(e2sum/n)
  fs = isc/2;
  printf "peak error %6.2f bits, %6.4f %%\n", emax, emax*100/fs
  printf "rms  error %6.2f bits, %6.4f %%\n", rms,  rms*100/fs
  if (emax*100/fs > .035 || rms*100/fs > 0.005) {
    print "FAIL"
    exit 1
  } else {
    print "PASS"
  }
}
