// Partially based on Verilator example module
#include <verilated.h>

// Include model header, generated from Verilating "pll_lock.v"
#include "Vpps_lock.h"
#include <verilated_fst_c.h>

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

	// Maybe these next three could come from plusargs?
	top->err_sign = 0;  // static
	top->dac_preset_val = 6000 + 32768;  // static
	top->fir_enable = 0;  // static

	// Internal simulation state
	int dds_accum = 0;
	int dac_hold = 0;
	static int dds_wrap = 1170960;  // 1/(4*0.014/2^16), 1.4% span

	// Goal is to see loop lock in ~60 ms, 60 "pps" pulses
	top->clk = 0;
	while (main_time < 60*1000*1000) {
		// modulate time between clock edges
		main_time += 4;  // Time passes in ticks of 8ns nominal
		dds_accum += (8000-dac_hold);  // increasing dac_hold -> higher frequeny
		if (dds_accum > dds_wrap) {dds_accum -= dds_wrap; main_time += 1;}
		if (dds_accum <        0) {dds_accum += dds_wrap; main_time -= 1;}
		top->clk = !top->clk;

		// build pps input
		// XXX need a halfway-realistic jitter/drift model
		unsigned int pps_phase = main_time % 1000000;  // 1 ms
		int pps0 = (pps_phase > 4) && (pps_phase < 30000);
		int pps1 = (pps_phase > 8) && (pps_phase < 30004);
		top->pps_in = (pps1 << 1) | pps0;  // or the other way around?

		// Startup control
		if (top->clk==1) top->run_request = main_time > 300000;

		// update dac on negedge clk; our dac_hold is signed
		if (top->clk==0 && top->dac_send) dac_hold = top->dac_data - 32768;

		// Evaluate model
		top->eval();

		// Dump trace data for this cycle
		if (tfp) tfp->dump (main_time);
	}

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
	exit(0);
}
