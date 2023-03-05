#include <signal.h>
#include <verilated.h>

// Include model header, generated from Verilating "cluster_wrap.v"
#include "Vcluster_wrap.h"
#include <verilated_vcd_c.h>

#include "udp_model.h"
unsigned short udp_port=0;  /* not used */
int badger_client=1;  /* not used */


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

	Vcluster_wrap* top = new Vcluster_wrap;

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
		tfp = new VerilatedVcdC;
		top->trace(tfp, 8, 0);  // Trace 8 levels of hierarchy
		tfp->open("Vatb.vcd");
	}

	// Determine UDP port numbers from command line options
	struct udp_state *udp_states[2];
	int badger_client_ = 1;  // only configuration used here
	for (unsigned jx=0; jx<2; jx++) {
		unsigned short udp_port_ = 3010 + jx;
		char *plus_name = strdup("udp_port0=");
		plus_name[8] += jx;
		const char* udp_arg = Verilated::commandArgsPlusMatch(plus_name);
		if (udp_arg && strlen(udp_arg) > 1) {
			const char* udp_int = strchr(udp_arg, '=');
			if (udp_int) {
				udp_port_ = strtol(udp_int+1, NULL, 10);
			}
		}
		free(plus_name);
		udp_states[jx] = udp_setup_r(udp_port_, badger_client_);
	}

	// Set some inputs
	// Brain-dead handling of two instances
	top->clk = 0;
	top->len_c_0 = 0;
	top->idata_0 = 0;
	top->raw_l_0 = 0;
	top->raw_s_0 = 0;
	top->len_c_1 = 0;
	top->idata_1 = 0;
	top->raw_l_1 = 0;
	top->raw_s_1 = 0;
	// not used yet
	int thinking = 1;
	// local state variables
	int txg_shift_0 = 0;
	int txg_shift_1 = 0;

	while (/* main_time < 1100 && */ !Verilated::gotFinish() && !interrupt_pending) {
		main_time += 4;  // Time passes in ticks of 8ns
		if (main_time % 4000000 == 0) printf("main_time %ld\n", main_time);
		// Toggle clocks and such
		top->clk = !top->clk;
		// Run UDP at falling edge of clk
		// variable names match client_sub.v
		if (top->clk==0) {
			{
				// channel 0: data from network -> simulation
				int udp_idata, udp_iflag, udp_count;
				udp_receiver_r(udp_states[0],
						&udp_idata, &udp_iflag, &udp_count,
						thinking);
				top->idata_0 = udp_idata;
				top->raw_l_0 = udp_iflag;
				top->raw_s_0 = udp_iflag && udp_count>0;
				top->len_c_0 = udp_count+8;
				// Delay raw_s by n_lat cycles to get output strobe
				int n_lat =  top->n_lat_expose;
				txg_shift_0 = (txg_shift_0 << 1) + top->raw_s_0;
				int txgg = txg_shift_0 >> (n_lat-1);
				// falling edge
				int opack_complete = (txgg & 3) == 2;
				int udp_oflag = (txgg & 2) == 2;
				// channel 0: data from simulation -> network
				if (udp_oflag) {
					udp_sender_r(udp_states[0], top->odata_0, opack_complete);
				}
			}
			{
				// channel 1: data from network -> simulation
				int udp_idata, udp_iflag, udp_count;
				udp_receiver_r(udp_states[1],
						&udp_idata, &udp_iflag, &udp_count,
						thinking);
				top->idata_1 = udp_idata;
				top->raw_l_1 = udp_iflag;
				top->raw_s_1 = udp_iflag && udp_count>0;
				top->len_c_1 = udp_count+8;
				// Delay raw_s by n_lat cycles to get output strobe
				int n_lat =  top->n_lat_expose;
				txg_shift_1 = (txg_shift_1 << 1) + top->raw_s_1;
				int txgg = txg_shift_1 >> (n_lat-1);
				// falling edge
				int opack_complete = (txgg & 3) == 2;
				int udp_oflag = (txgg & 2) == 2;
				// channel 1: data from simulation -> network
				if (udp_oflag) {
					udp_sender_r(udp_states[1], top->odata_1, opack_complete);
				}
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
