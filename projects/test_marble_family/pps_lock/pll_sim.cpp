// Partially based on Verilator example module
#include <verilated.h>

// Include model header, generated from Verilating "pll_lock.v"
#include "Vpps_lock.h"
#include <verilated_fst_c.h>
// supplied by tt800.c
unsigned long genrand(void);

// 32-bit input version, popularized in Linux kernel bitops.h
static unsigned int countbits(unsigned long ux)
{
	ux = (ux & 0x55555555) + ((ux >> 1) & 0x55555555);  // pairs
	ux = (ux & 0x33333333) + ((ux >> 2) & 0x33333333);  // quads
	ux = (ux + (ux >> 4)) & 0x0f0f0f0f;                 // octets
	ux = (ux * 0x01010101) >> 24;                       // sum of octets
	return ux & 0xff;
}

// Pseudo-random number generator with approximately Gaussian distribution
// Mean of 16, variance of 32/4, standard deviation approx. 2.83, peak/rms = 5.66
static unsigned int grand(void)
{
	unsigned long rint = genrand();
	return countbits(rint);
}

// Current simulation time (64-bit unsigned)
vluint64_t main_time = 0;
// Called by $time in Verilog
double sc_time_stamp() {
	return main_time;  // Note does conversion to real, to match SystemC
}

int main(int argc, char** argv, char** env) {

	Verilated::commandArgs(argc, argv);
	Verilated::debug(0);

	Vpps_lock* top = new Vpps_lock;

	// Tracing (vcd)
	VerilatedFstC* tfp = NULL;
	const char* flag = Verilated::commandArgsPlusMatch("trace");
	if (flag && 0==strcmp(flag, "+trace")) {
		Verilated::traceEverOn(true);
		// VL_PRINTF("Enabling waves into logs/vlt_dump.vcd...\n");
		tfp = new VerilatedFstC;
		top->trace(tfp, 9);  // Trace 9 levels of hierarchy
		// Verilated::mkdir("logs");
		tfp->open("pll_sim.vcd");  // Open the dump file
	}

	// User-configurable
	const char* flag2 = Verilated::commandArgsPlusMatch("fir_enable");
	top->fir_enable = (flag2 && 0==strcmp(flag2, "+fir_enable"));

	// These three could also potentially come from plusargs
	top->fine_sel = 0;  // static
	top->err_sign = 0;  // static
	top->dac_preset_val = 7500 + 32768;  // static

	// Internal simulation state
	int dds_accum = 0;
	int dac_hold = 0;
	static int dds_wrap = 1170960;  // 1/(4*0.014/2^16), 1.4% span
	unsigned int jitter = 0;
	int updated_jitter = 0;
	int dsp_on = 0;
	int bad_phase = 0;
	int stat_n = 0;
	int stat_v = 0;

	// Goal is to see loop lock in ~60 ms, 60 "pps" pulses
	top->clk = 0;
	while (main_time < 80*1000*1000) {
		// modulate time between clock edges
		main_time += 4;  // Time passes in ticks of 8ns nominal
		dds_accum += (8000-dac_hold);  // increasing dac_hold -> higher frequeny
		if (dds_accum > dds_wrap) {dds_accum -= dds_wrap; main_time += 1;}
		if (dds_accum <        0) {dds_accum += dds_wrap; main_time -= 1;}
		top->clk = !top->clk;

		// build pps input
		// Include halfway-realistic jitter model, but no drift or 1/f noise
		if (top->clk == 1) {
			unsigned int pps_phase = main_time % 1000000;  // 1 ms
			// only update jitter once per pps edge
			if (pps_phase < 10 && updated_jitter == 0) {
				jitter = grand()*2;  // planned jitter 5.66 ns rms
				if (0) printf("new jitter %u\n", jitter);
				updated_jitter = 1;
			} else if (pps_phase > 100) {
				updated_jitter = 0;
			}
			pps_phase += jitter;
			int pps0 = (pps_phase > 34) && (pps_phase < 30000);
			int pps1 = (pps_phase > 38) && (pps_phase < 30004);
			top->pps_in = (pps0 << 1) | pps1;  // confirmed on hardware
		}

		// Startup control
		if (top->clk==1) top->run_request = main_time > 2500000;

		// update dac on negedge clk; our dac_hold is signed
		if (top->clk==0 && top->dac_send) {
			dac_hold = top->dac_data - 32768;
			unsigned dsp_status = top->dsp_status;
			// next few lines exactly match stanza found in lock_vcxo.py
			int dsp_arm = (dsp_status >> 12) & 1;
			dsp_on = (dsp_status >> 13) & 1;
			int pha = dsp_status & 0xfff;
			if (pha > 2047) pha -= 4096;
			printf("%d %u %u %d\n", top->dac_data, dsp_on, dsp_arm, pha);
			if (main_time > 50000000) {
				if ((pha > 6) || (pha < -6)) bad_phase=1;
				stat_n += 1;
				stat_v += pha*pha;
			}
		}

		// Evaluate model
		top->eval();

		// Dump trace data for this cycle
		if (tfp) tfp->dump (main_time);
	}
	double rms = 4.0 * sqrt(stat_v/(double) stat_n);
	printf("stat_n = %d   stat_v = %d   rms = %.3f ns\n", stat_n, stat_v, rms);
	if (bad_phase) printf("Excess peak phase\n");

	// Final model cleanup
	top->final();
	if (tfp) { tfp->close(); tfp = NULL; }

	//  Coverage analysis (since test passed)
#if VM_COVERAGE
	Verilated::mkdir("logs");
	VerilatedCov::write("logs/coverage.dat");
#endif

	// Destroy model
	delete top;

	// Fin
	// Return code for regression test; 0 is success
	int rc = (dsp_on == 1 && bad_phase == 0) ? 0 : 1;
	printf("%s\n", (rc==0) ? "PASS" : "FAIL");
	return rc;
}
