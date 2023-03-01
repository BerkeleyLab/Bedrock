// Partially based on Verilator example module
#include <signal.h>
#include <verilated.h>

// Include model header, generated from Verilating "mem_gateway_wrap.v"
#include "Vmem_gateway_wrap.h"
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

	Vmem_gateway_wrap* top = new Vmem_gateway_wrap;

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
		tfp->open("mem_gateway2.vcd");  // Open the dump file
	}

	// Determine UDP port number from command line options
	udp_port = 3010;  // default
	badger_client = 1;  // only configuration used here
	const char* flag2 = Verilated::commandArgsPlusMatch("udp_port=");
	if (strlen(flag2) > 1) {
		for (int n = 0; n < strlen(flag2); n++) {
			if (*(flag2+n) == '=') {
				flag2 += n + 1;
				break;
				}
			}
			udp_port = strtol(flag2, NULL, 10);
	}

	// Set some inputs
	top->clk = 0;
	top->len_c= 0;
	top->idata = 0;
	top->raw_l = 0;
	top->raw_s = 0;
	// not used yet
	int thinking = 0;
	// local state variable
	int txg_shift = 0;

	while (/* main_time < 1100 && */ !Verilated::gotFinish() && !interrupt_pending) {
		main_time += 4;  // Time passes in ticks of 8ns
		// Toggle clocks and such
		top->clk = !top->clk;

		// Run UDP at falling edge of clk
		// variable names match client_sub.v
		if (top->clk==0) {
			// data from network -> simulation
			int udp_idata, udp_iflag, udp_count;
			udp_receiver(
				&udp_idata, &udp_iflag, &udp_count,
				thinking);
			if (0) {  // Should never happen
				VL_PRINTF("Ethernet is dead\n");
				exit(1);
			}
			// VL_PRINTF("foo %2x %d %d\n", udp_idata, udp_iflag, udp_count);
			top->idata = udp_idata;
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
				udp_sender(top->odata, opack_complete);
			}
		}

		// Evaluate model
		top->eval();

		// Dump trace data for this cycle
		if (tfp) tfp->dump (main_time);
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
