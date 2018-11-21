load "half_filt.dat"
y=half_filt;
npt=length(y);
printf('read %d points, expected 245\n',npt);
ix=[1:npt]';
s=sin((ix+2.0)*.0081*2*16);
lf1=polyfit(s,y,1);
oamp=lf1(1);
printf('actual amplitude %8.1f, expected about 200000\n', oamp);
erry=y-lf1(1)*s;
err=std(erry);
printf('DC offset     %.4f bits, expected about 0\n', mean(erry));

nom_err=sqrt(1.0^2+1/12)*0.66787;
printf('std deviation %.4f bits, expected about %.4f\n', err, nom_err);
printf('excess noise  %.4f bits\n', sqrt(err^2-nom_err^2));
if ((npt>240) && (oamp > 199800) && (oamp < 200000) && (abs(mean(erry)) < 0.01) && (err < sqrt(nom_err^2 + 0.3^2)))
  printf("PASS\n");
else
  printf("FAIL\n");
  exit(1);
end
