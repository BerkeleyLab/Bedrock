import sys
import numpy

if len(sys.argv) < 2:
    print(f"USAGE: python3 {sys.argv[0]} dpw [filename]")
    sys.exit(1)

dpw = int(sys.argv[1])  # data path width


if len(sys.argv) > 2:
    filename = sys.argv[2]
    print(f"Writing to filename {filename}")
    fd = open(filename, 'w')
else:
    fd = None


def _print(fd, *args, **kwargs):
    if fd is None:
        print(*args, **kwargs)
    else:
        print(*args, **kwargs, file=fd)


try:
    _print(fd, '// CORDIC processor, machine generated from cordicgx.py')
    _print(fd, '// %d is the internal data path width' % dpw)
    _print(fd, 'module cordicg_b%d #(' % dpw)

    _print(fd, '    parameter width=19,')
    _print(fd, '    parameter nstg=%d,' % (dpw-1))
    _print(fd, '''    parameter def_op=0
) (
    input clk,
    input [1:0] opin,
    //  opin = 1 forces y to zero (rect to polar),
    //  opin = 0 forces theta to zero (polar to rect),
    //  opin = 3 for follow mode
    input [width-1:0] xin,
    input [width-1:0] yin,
    input [width:0] phasein,
    output [width-1:0] xout,
    output [width-1:0] yout,
    output [width:0] phaseout
);

// input buffer stage (routing)
reg [1:0] opin0=def_op;
reg [width-1:0] xin0=0, yin0=0;
reg [width:0] phasein0=0;
always @(posedge clk) begin
    opin0    <= opin;
    xin0     <= xin;
    yin0     <= yin;
    phasein0 <= phasein;
end

// zero stage: doesn't quite fit the pattern
reg  [1:0] op0=def_op;
wire [width-1:0] xw0,  yw0  ; wire [width:0] zw0;
reg  [width-1:0] x0=0, y0=0 ; reg  [width:0] z0=0;
wire control0_l = opin0[0] ? xin0[width-1] : phasein0[width]^phasein0[width-1];
reg control0_h=0;
// No inversion of control0_h, unlike all the other stages!
// Rotation is either 0 or 180, which are their own inverses.
wire control0 = opin0[1] ? control0_h : control0_l;
addsubg #(width) ax0 ({width{1'b0}}, xin0, xw0, ~control0);
addsubg #(width) ay0 ({width{1'b0}}, yin0, yw0, ~control0);
assign zw0 = {phasein0[width]^control0,phasein0[width-1:0]};
always @(posedge clk) begin
   op0 <= opin0;
   x0 <= xw0;
   y0 <= yw0;
   z0 <= zw0;
   control0_h <= control0_l;
end

// first stage: can't use cstageg because repeat operator of zero is illegal
reg  [1:0] op1=def_op;
wire [width-1:0] xw1,   yw1   ; wire [width:0] zw1;
reg  [width-1:0] xt1=0, yt1=0 ; reg  [width:0] zt1=0;
wire control1_l = op0[0] ? ~y0[width-1] : z0[width];
reg control1_h=0;
wire control1 = op0[1] ? ~control1_h : control1_l;
addsubg #(width) ax1 (x0, y0, xw1,  control1);
addsubg #(width) ay1 (y0, x0, yw1, ~control1);
addsubg #(width+1) az1 (z0, {3'b001,{(width-2){1'b0}}}, zw1,  control1);
always @(posedge clk) begin
    op1 <= op0;
    xt1 <= xw1;
    yt1 <= yw1;
    zt1 <= zw1;
    control1_h <= control1_l;
end
''')

    _print(fd, 'wire [1:0] opn[1:%d];' % (dpw-1))
    _print(fd, 'wire [%d:0] xn[1:%d], yn[1:%d];' % (dpw-1, dpw-1, dpw-1))
    _print(fd, 'wire [%d:0] zn[1:%d];' % (dpw, dpw-1))

    _print(fd, 'assign opn[1] = op1;')
    _print(fd, 'assign xn[1] = {xt1,{(%d-width){1\'b0}}};' % dpw)
    _print(fd, 'assign yn[1] = {yt1,{(%d-width){1\'b0}}};' % dpw)
    _print(fd, 'assign zn[1] = {zt1,{(%d-width){1\'b0}}};' % dpw)

    # Heart of the matter
    for ix in range(1, dpw-1):
        a = numpy.floor(numpy.arctan((0.5)**ix)/(2*numpy.pi)*2**(dpw+1)+.5)
        ss = 'cstageg #( %2d, %d, %d, def_op) cs%-2d (' % (ix, dpw+1, dpw, ix)
        ss += ' clk, opn[%-2d], xn[%-2d],  yn[%-2d], zn[%-2d],' % (ix, ix, ix, ix)
        ss += ' %2d\'d%-9ld,' % (dpw+1, a)
        ss += ' opn[%-2d], xn[%-2d],  yn[%-2d],  zn[%-2d]);' % (ix+1, ix+1, ix+1, ix+1)
        _print(fd, ss)

    # This rounding construction can be considered wasteful; it adds
    # hardware and slows the logic down.  OTOH, I haven't found any
    # alternative that works as well.

    _print(fd, 'wire [%d:0] xfinal = xn[nstg-1];' % (dpw-1))
    _print(fd, 'wire [%d:0] yfinal = yn[nstg-1];' % (dpw-1))
    _print(fd, 'wire [%d:0] zfinal = zn[nstg-1];' % (dpw))
    _print(fd, '\n// round, not truncate')
    _print(fd, 'assign xout     = xfinal[%d:%d-width] + xfinal[%d-width];' % (dpw-1, dpw, dpw-1))
    _print(fd, 'assign yout     = yfinal[%d:%d-width] + yfinal[%d-width];' % (dpw-1, dpw, dpw-1))
    _print(fd, 'assign phaseout = zfinal[%d:%d-width] + zfinal[%d-width];' % (dpw, dpw, dpw-1))

    _print(fd, '\nendmodule')
except Exception as e:
    print(e)
finally:
    if fd is not None and hasattr(fd, 'close'):
        print("Closing")
        fd.close()
