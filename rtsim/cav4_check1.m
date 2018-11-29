d = load('cav4_mode.dat');
npt = size(d,1);

den = 33;
n2 = floor(npt/den);
ix = [1:n2*den]';
dt = 14/1320;  % us
t = dt*ix;

mr = d(ix,1)+i*d(ix,2);
st = d(ix,3)+i*d(ix,4);
pr = d(ix,5);
rf = d(ix,6);
m2 = d(ix,7);

lo = exp(ix*2*pi*i*7/den);
rx = rf.*lo;  rxr = reshape(rx(1:den*n2),den,n2)';  rxa=mean(rxr,2);
t2 = dt*den*([1:n2]'-0.5);

kx = find(t2>8);
pp = polyfit(t2(kx),arg(rxa(kx)),1);
detune=pp(1)/(2*pi);
printf('phase slope %.2f kHz\n',detune*1e3)

figure(1)
plot(t2,real(rxa),t2,imag(rxa),t2,abs(rxa))
legend('real','imag','abs')
xlabel('t ({/Symbol m}sec)')
title('cav4\_mode.v pulse response')
figure(2)
plot(t2,angle(rxa),t2(kx),polyval(pp,t2(kx)))
legend('phase simulated',sprintf('phase fit, slope %.2f kHz\n',detune*1e3))
xlabel('t ({/Symbol m}sec)')
ylabel('radians')

mech_freq = 2000000;  % pasted from cav4_mode_tb.v
detune_theory = -mech_freq/2^32/dt;  % XXX negative is ugly
err = detune/detune_theory-1

if (abs(err) > 0.004)
  printf('FAIL\n')
  exit(1)
else
  printf('PASS\n')
end
