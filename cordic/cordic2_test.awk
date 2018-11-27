# cordic2_test.awk
# Larry Doolittle, LBNL

# Check for bias in cordic2.dat

BEGIN{
  sum_cos=0
  sum_sin=0
  n=0
}
/^xxx width/{width=$3; isc=2^width;}
!/x/{
  if (n<61*100+2) {
    if (n>=2) {
      # print $0
      sum_cos += $4
      sum_sin += $5
    }
    n += 1
  }
}
END{
  printf "test covers %d points\n", n
  printf "averages %.3f %.3f\n", sum_cos/n, sum_sin/n
  mv = (sum_cos*sum_cos + sum_sin*sum_sin)/(n*n)
  if (mv > 0.001) {
    print "FAIL"
    exit 1
  } else {
    print "PASS"
  }
}
