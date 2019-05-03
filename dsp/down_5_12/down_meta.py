import numpy as np

# XXX add comments!
x = np.arange(12)
xo = 0.5  # pleasing symmetry
xo = 0.2  # equal SNR on I and Q
t = (x+xo)*5/12*2*np.pi
z = np.exp(1j*t)
npt = 6
dc = np.arange(npt)*0+1
fmt = "\t%2d: begin  ref_i <= %6d;  ref_q <= %6d;  ref_dc <= %6d;  end"
print("always @(posedge clk) case (phase)")
for ix in [0, 6]:
    vr = z[ix:ix+npt].real
    vi = z[ix:ix+npt].imag
    basis = np.vstack([vr, vi, dc])
    v = np.identity(npt)
    fitc, resid, rank, sing = np.linalg.lstsq(basis.T, v, rcond=-1)
    fitc_scaled = np.round(2**18 * fitc.T)
    for jx in range(npt):
        pp = tuple([ix+jx] + list(fitc_scaled[jx]))
        print(fmt % pp)
print("\tdefault: begin  ref_i <= 18'bx; ref_q <= 18'bx; ref_dc <= 18'bx; end")
print("endcase")
print("")

fmt = "\t%2d: begin  tone_i <= %7d;  tone_q <= %7d;  end"
print("always @(posedge clk) case (phase)")
for jx in range(12):
    v = np.round(2**17 * z[jx])
    pp = (jx+8) % 12, v.real, v.imag
    print(fmt % pp)
print("\tdefault: begin  tone_i <= 18'bx;  tone_q <= 18'bx;  end")
print("endcase")
print("")

pp = tuple(sum(abs(fitc_scaled)/8))
print("// ref_ sum(abs())/8:  %d %d %d" % pp)

for ix in [0, 1]:
    a = fitc[ix]
    # print(a)
    # print("%9.6f %9.6f %9.6f" % (a.dot(vr), a.dot(vi), a2))
    a2 = a.dot(a)
    pg = -np.log10(a2)*10
    print("// processing gain %6.3f dB" % pg)
pg = np.log10(3)*10
print("// relative to %6.3f dB possible without DC rejection" % pg)
