#include <stdio.h>
#include <math.h>
#include <string.h>  /* strdup */
#include <stdlib.h>  /* exit */
#ifndef M_PI
#define M_PI           3.14159265358979323846
#endif

// pull in EXTRA and MW from sim1.h
#include "sim1.h"
#define SCE (1<<EXTRA)
#define VMAX (1<<(PW-1+EXTRA))
#define MUL_SHF (PW + EXTRA - MW)

// The intent here is to be a bit-accurate representation
// of the processing done on the FPGA.
// It's nowhere close to cycle-accurate, but the tests can overlook that.

#define F(a) ((double)(a)/(double)VMAX)

int verbose = 1;
#define TRACE (verbose>1)
#define VERBOSE (verbose)

// In nominal configuration, shifter input is 21 bits, output is 18 bits
// Valid shift values are 0, 1, 2, and 3.
static int shifter(int a, int shift, const char *label)
{
	if (TRACE) printf("shifter in  %d (%+8.5f)\n", a, F(a));
	a = a>>(3-shift);
	if (a> (VMAX-1)) a=  VMAX-1;
	if (a< (-VMAX )) a= -VMAX;
	if (VERBOSE) printf("%s result %9d (%+8.5f)\n", label, a, F(a));
	return a;
}

static int mul(int a, int b, int shift)
{
	long long r = (long long)(a>>MUL_SHF)*(long long)(b>>MUL_SHF);
	if (TRACE) printf("multiply %lld = %d * %d\n", r, a, b);
	return shifter(r>>(2*MW-22-EXTRA), shift, "mul");
}

static int add(int a, int b, int shift)
{
	int r = a + b;
	if (TRACE) printf("add %d = %d + %d\n", r, a, b);
	return shifter(r<<2, shift, "add");
}

static int sub(int a, int b, int shift)
{
	int r = a - b;
	if (TRACE) printf("sub %d = %d - %d\n", r, a, b);
	return shifter(r<<2, shift, "sub");
}

static int inv(int a, int shift)
{
	// Lots of ugly special cases
	const unsigned int iscale = 8;
	unsigned int u = (a<0) ? -a : a;
	u = u >> (18+EXTRA-2-iscale);
	unsigned int u0 = u;  // almost just for printing
	unsigned int ur;
	for (ur = 512; u>3; ur = ur >> 1) u = u >> 1;
	// u is now typically 2 or 3
	if (u==2) ur = ur + ur/2;
	ur /= 2;
	if (u0<2) ur=512;
	if (u0==0) ur=1023;
	// printf("LUT in %d out %d\n", u0, ur);
	int r = (a<0) ? -ur : ur;
	r = r << (18+4+EXTRA-3-iscale);
	if (TRACE) printf("inv %d (%.5f) [%u] %d (%.5f)\n", a, F(a), u, r, F(r));
	return shifter(r, shift, "inv");
}

static int invsqrt(int a, int shift)
{
	// Using convention that a represents -1 to 1, start by taking abs(a).
	// Design input range 1/64 to 1, output range 1 to 1/8.
	// Actual function approximated is therefore 1/(8*sqrt(a)).
	// Table is segmented into three ranges of two octaves each; see sqrt1.py.
	// Lots of ugly special cases.
	const unsigned int iscale = 8;
	unsigned int u = (a<0) ? -a : a;
	u = u >> (18+EXTRA-2-iscale);
	unsigned int u0 = u;  // almost just for printing
	unsigned int ur;
	for (ur = 512; u>7; ur = ur >> 1) u = u >> 2;
	switch(u) {
	  case 2: ur = ur + 3*ur/4; break;
	  case 3: ur = ur + ur/2; break;
	  case 4: ur = ur + ur/4; break;
	  case 5: ur = ur + ur/4; break;
	  default: break;
	}
	if (u0<2) ur=1023;
	// printf("LUT in %d out %d\n", u0, ur);
	int r = (a<0) ? -ur : ur;
	r = r << (18+4+EXTRA-3-iscale);
	if (TRACE) printf("invsqrt %d (%.5f) [%u] %d (%.5f)\n", a, F(a), u, r, F(r));
	return shifter(r, shift, "invsqrt");
}


static void set_result_ab(int a, int b)
{
	printf("result_ab %.6f %.6f\n", F(a), F(b));
}

static void set_result_cd(int a, int b)
{
	printf("result_cd %.6f %.6f\n", F(a), F(b));
}

// Brain-dead quadratic-time hard-limited setup for a "dictionary"
// Simpler and more reliable than requiring some external library.
#define MAX_PERSIST 20
struct persist_var { char *name; int value; } persist_list[MAX_PERSIST];
unsigned persist_count = 0;

static int persist_get(const char *name)
{
	for (unsigned u=0; u<persist_count; u++) {
		if (strcmp(name, persist_list[u].name) == 0) {
			return persist_list[u].value;
		}
	}
	return 0;  // default if not found
}

static void persist_set(const char *name, int val)
{
	if (persist_count == MAX_PERSIST) {
		fprintf(stderr, "Out of memory for persistent name %s\n", name);
		exit(1);
	}
	persist_list[persist_count].name = strdup(name);
	persist_list[persist_count].value = val;
	persist_count++;
}

static void cycle(int given[])
{
// suck in the machine-generated instruction sequence
static int init=1;
#include "ops.h"
init = 0;
}

static void invcheck(void)
{
	// See invcheck.py
	int two = 131072;  // 1/16.0
	for (int x = 2500; x < 2090000; x += 7*x/300) {
		int s_guess = inv(x, 0);
		// refinement 1
		int s_r2_e = mul(s_guess, x, 3);
		int s_r2_f = sub(two, s_r2_e, 3);
		int s_r2 = mul(s_guess, s_r2_f, 3);
		// refinement 2
		int s_r1_e = mul(s_r2, x, 3);
		int s_r1_f = sub(two, s_r1_e, 3);
		int s_r1 = mul(s_r2, s_r1_f, 3);
		// refinement 3
		int s_e = mul(s_r1, x, 3);
		int s_f = sub(two, s_e, 3);
		int s = mul(s_r1, s_f, 3);
		//
		long int perfect = 17179869184L / (long) x;
		printf("plot %7d %7d %7d %7d %7d %7ld\n", x, s_guess, s_r2, s_r1, s, perfect);
	}
}

static int invsqrtcheck(void)
{
	int three = 786432;  // 3/8.0
	int fail = 0;
	for (int x = 2500; x < 2090000; x += 7*x/300) {
		int s_r0 = invsqrt(x, 0);
		// refinement 1
		int s_r0_s = mul(s_r0, s_r0, 0);
		int s_r0_p = mul(s_r0_s, x, 3);
		int s_r0_d = sub(three, s_r0_p, 1);
		int s_r1 = mul(s_r0, s_r0_d, 2);
		// refinement 2
		int s_r1_s = mul(s_r1, s_r1, 0);
		int s_r1_p = mul(s_r1_s, x, 3);
		int s_r1_d = sub(three, s_r1_p, 1);
		int s_r2 = mul(s_r1, s_r1_d, 2);
		// refinement 3
		int s_r2_s = mul(s_r2, s_r2, 0);
		int s_r2_p = mul(s_r2_s, x, 3);
		int s_r2_d = sub(three, s_r2_p, 1);
		int s = mul(s_r2, s_r2_d, 2);
		//
		double check = ((long int)s*(long int)s)/2097152*x/68719476736.0;
		int fault = (x > 32768) && ((check > 1.0005 || check < 0.9999));
		if (fault) fail = 1;
		printf("plot %7d %7d %7d %7d %7d %.6f %s\n", x, s_r0, s_r1, s_r2, s, check, fault ? "BAD" : ".");
	}
	return fail;
}

static void file_loop(const char *fname, int given[], unsigned given_size)
{
	char iline[80];
	FILE *file2 = fopen(fname, "r");
	long int r[8];
	const int fs = 64;  // Input file is 16 bits, simulator is 22 bits
	while (fgets(iline, sizeof(iline), file2)) {
		// printf("%s", iline);
		char *ss = iline;
		for (unsigned jx=0; jx<8 && ss; jx++) {
			r[jx] = strtol(ss, &ss, 0);
			// printf("%ld\n", r[jx]);
		}
		// Provision for channel remapping, not used, hurray!
		given[0] = r[2]*fs;  given[1] = r[3]*fs;  // forward
		given[2] = r[4]*fs;  given[3] = r[5]*fs;  // reverse
		given[4] = r[6]*fs;  given[5] = r[7]*fs;  // cavity
		for (unsigned u=0; u<given_size; u++) {
			printf("%3u: given %9d (%+8.5f)\n", u, given[u], (double)given[u]/(double)VMAX);
		}
		cycle(given);
	}
}

int main(int argc, char *argv[])
{
	if ((argc > 1) && strcmp(argv[1], "invcheck")==0) {
		invcheck();
		return 0;
	}
	if ((argc > 1) && strcmp(argv[1], "invsqrtcheck")==0) {
		int rc =invsqrtcheck();
		printf(rc ? "FAIL\n" : "PASS\n");
		return rc;
	}
	unsigned int u, given_size;
	int given[16];
	char iline[80];
	printf("Starting C-based bit-accurate simulator\n");
	char pname[80];
	unsigned dummy;
	char type;
	int val;
	u = 0;
	// init.dat must keep the s, h order matching how the sf_user module
	// streams data to the ALU.
	while (fgets(iline, sizeof(iline), stdin)) {
		if (*iline == '#') {
		} else if ((*iline == 's' || *iline == 'h') && 3 == sscanf(iline, "%c %u %d", &type, &dummy, &val)) {
			given[u++] = SCE * val;
		} else if (*iline == 'p' && 3 == sscanf(iline, "%c %20s %d", &type, pname, &val)) {
			persist_set(pname, SCE * val);
		}
	}
	given_size = u;
	printf("read initialization file, %u\n", given_size);

	if (argc > 1) {
		file_loop(argv[1], given, given_size);
	} else {
		for (u=0; u<given_size; u++) {
			printf("%3u: given %9d (%+8.5f)\n", u, given[u], (double)given[u]/(double)VMAX);
		}
		cycle(given);
	}
	return 0;
}
