// Based on mem_gateway_sim.cpp
// in turn partly based on Verilator example module

#include <signal.h>
#include <verilated.h>

// Include model header, generated from Verilating "jit_rad_gateway_demo.v"
#include "Vjit_rad_gateway_demo.h"
#include <verilated_vcd_c.h>

#include "udp_model.h"
unsigned short udp_port;  /* Global, set below */
int badger_client;        /* Global, set below */

// Current simulation time (64-bit unsigned)
vluint64_t main_time = 0;
// Called by $time in Verilog
double sc_time_stamp() {
	return main_time;  // Note does conversion to real, to match SystemC
}

int interrupt_pending=0;  // Global
void interrupt_handler(int s){
	interrupt_pending = 1;
}

int main(int argc, char** argv, char** env) {

	Verilated::commandArgs(argc, argv);
	Verilated::debug(0);

	Vjit_rad_gateway_demo* top = new Vjit_rad_gateway_demo;

	// Boilerplate to set up trapping of control-C
	struct sigaction sigIntHandler;
	sigIntHandler.sa_handler = interrupt_handler;
	sigemptyset(&sigIntHandler.sa_mask);
	sigIntHandler.sa_flags = 0;
	sigaction(SIGINT, &sigIntHandler, NULL);

	// Tracing (vcd)
	VerilatedVcdC* tfp = NULL;
	const char* flag = Verilated::commandArgsPlusMatch("trace");
	if (flag && 0==strcmp(flag, "+trace")) {
		Verilated::traceEverOn(true);
		// VL_PRINTF("Enabling waves into logs/vlt_dump.vcd...\n");
		tfp = new VerilatedVcdC;
		top->trace(tfp, 9);  // Trace 9 levels of hierarchy
		// Verilated::mkdir("logs");
		tfp->open("xfer_demo.vcd");  // Open the dump file
	}

	// Determine UDP port number from command line options
	udp_port = 3010;  // default
	badger_client = 1;  // only configuration used here
	const char* udp_arg = Verilated::commandArgsPlusMatch("udp_port=");
	if (udp_arg && strlen(udp_arg) > 1) {
		const char* udp_int = strchr(udp_arg, '=');
		if (udp_int) udp_port = strtol(udp_int+1, NULL, 10);
	}

	// Set some inputs
	top->lb_clk = 0;
	top->len_c= 0;
	top->net_idata = 0;
	top->raw_l = 0;
	top->raw_s = 0;
	top->app_clk = 0;
	// not used yet
	int thinking = 0;
	// local state variable
	int txg_shift = 0;

	while (/* main_time < 1100 && */ !Verilated::gotFinish() && !interrupt_pending) {
		int eval_pending = 0;
		main_time += 1;  // Time passes
		if ((main_time % 4) == 0) {
			top->lb_clk = !top->lb_clk;
			// Run UDP at falling edge of lb_clk
			// variable names match client_sub.v
			if (top->lb_clk==0) {
				// data from network -> simulation
				int udp_idata, udp_iflag, udp_count;
				udp_receiver(
					&udp_idata, &udp_iflag, &udp_count,
					thinking);
				// VL_PRINTF("foo %2x %d %d\n", udp_idata, udp_iflag, udp_count);
				top->net_idata = udp_idata;
				top->raw_l = udp_iflag;
				top->raw_s = udp_iflag && udp_count>0;
				top->len_c = udp_count+8;
				// Delay raw_s by n_lat cycles to get output strobe
				int n_lat =  top->n_lat_expose;
				txg_shift = (txg_shift << 1) + top->raw_s;
				int txgg = txg_shift >> (n_lat-1);
				// falling edge
				int opack_complete = (txgg & 3) == 2;
				int udp_oflag = (txgg & 2) == 2;
				// data from simulation -> network
				if (udp_oflag) {
					udp_sender(top->net_odata, opack_complete);
				}
			}
			eval_pending = 1;
		}
		if ((main_time % 11) == 0 || (main_time % 11) == 5) {  // 11 ns per cycle, which is close to 10.606 of lcls2_llrf
			top->app_clk = !top->app_clk;
			eval_pending = 1;
		}
		if (eval_pending) {
			// Evaluate model
			top->eval();
			// Dump trace data for this cycle
			if (tfp) tfp->dump (main_time);
		}
	}

	// Final model cleanup
	VL_PRINTF("Loop exit: interrupt_pending = %d\n", interrupt_pending);
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
