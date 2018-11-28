d=load('resonator.dat');
z=d(:,1)+i*d(:,2);
%plot(z)
npt=length(z);

% register settings, copied from resonator_tb.v
init_reg = 100000000+50000000i;
init_reg = 100000000;
drive_reg = 0 + 1000i;
a_reg = -80000 + 120000i;
scale_reg = 7;

% abstract values
init = init_reg/2^18;
drive = drive_reg/16;  % XXX depends on scale_reg
a = 1+a_reg/2^17/2^18*4^scale_reg
% now z*v = a*v + drive

% in equilibrium, v=drive/(1-a)
term = drive/(1-a);
% should be about -756 + 503i;

zz = z-term;
r = mean(zz(2:50)./zz(1:50-1))
% and this checks, a \approx r

% direct model, matches except for roundoff errors?
sim=filter(1,[1 -a],ones(npt,1)*drive,init*a);

plot(real(z), imag(z), real(sim), imag(sim), real(term), imag(term), '+')
legend('Simulated resonator.v','Octave filter()')
axis([-1 1 -1 1]*1000,'square')
title('1 of m mechanical modes, response to DC drive')

t=[0:npt-1]';  % abstract
if 0
  plot(t,real(z),t,real(sim))
end

err=std(z-sim)
if (abs(err) > 0.6)
  printf('FAIL\n')
  exit(1)
else
  printf('PASS\n')
end
