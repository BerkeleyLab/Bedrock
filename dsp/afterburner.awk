BEGIN{fail=0}
# $1>310 && $2==1{print $1,$3,2000*sin((FNR-4)/2*op_num/den*2*3.14159)}
$1>400 && $1<1180{
  v=1000*sin((FNR-12-2*ab_tri)/2*op_num/den*2*3.14159)
  # printf "%4d %5d %8.2f %6.2f %d\n", $1,$4,v,$4-v,fail
  if ($4>v+1.3 || $4<v-1.3) fail++
}
END{
  if (fail==0) print "PASS"
  exit(fail>0)
}
