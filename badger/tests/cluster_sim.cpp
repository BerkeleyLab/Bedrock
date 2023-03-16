#include <signal.h>
#include <verilated.h>

// Include model header, generated from Verilating "cluster_wrap.sv"
// See cluster_wrap.sv for more comments about the scope and purpose
// of this simulation.
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

	int cluster_n = 0;  // will be filled in from cluster_n_expose port
	int badger_client_ = 1;  // only configuration used here
	// Determine UDP port base from command line option
	int udp_port_base = 3010;
	const char* udp_arg = Verilated::commandArgsPlusMatch("udp_port_base=");
	if (udp_arg && strlen(udp_arg) > 1) {
		const char* udp_int = strchr(udp_arg, '=');
		if (udp_int) udp_port_base = strtol(udp_int+1, NULL, 10);
	}

	// persistent storage
	int n_lat = 0;  // disable first iteration
	int thinking = 1;  // not used yet
	// following two need a malloc to get arrays of length cluster_n;
	int *txg_shifts=NULL;
	// udp_states is the result of a malloc.  *udp_states is the first
	// element of an array of pointers to udp_state.
	struct udp_state **udp_states=NULL;
	//
	top->cluster_in = 0;

	while (/* main_time < 1100 && */ !Verilated::gotFinish() && !interrupt_pending) {
		main_time += 4;  // Time passes in ticks of 8ns
		if (main_time % 4000000 == 0) printf("main_time %ld\n", main_time);
		// Toggle clocks and such
		top->clk = !top->clk;
		// Run UDP at falling edge of clk
		// variable names match client_sub.v
		if (top->clk==0) {
			// Pretty ugly work around for verilator issue #860
			// Still not as bad as hand-unrolling the loop
			uint64_t client_xx=0;
			if (n_lat != 0) for (unsigned jx=0; jx<cluster_n; jx++) {
				// channel 0: data from network -> simulation
				int udp_idata, udp_iflag, udp_count;
				udp_receiver_r(udp_states[jx],
						&udp_idata, &udp_iflag, &udp_count,
						thinking);
				unsigned int client_idata = udp_idata;
				unsigned int client_raw_l = udp_iflag;
				unsigned int client_raw_s = udp_iflag && udp_count>0;
				unsigned int client_len_c = udp_count+8;
				// hope this matches systemverilog struct packed client_in
				uint64_t client_x =
					(client_len_c << 10) |
					(client_idata << 2) |
					(client_raw_l << 1) |
					(client_raw_s << 0);
				client_xx = (client_x << (21*jx)) | client_xx;
				//
				// Delay raw_s by n_lat cycles to get output strobe
				txg_shifts[jx] = (txg_shifts[jx] << 1) + client_raw_s;
				int txgg = txg_shifts[jx] >> (n_lat-1);
				// falling edge
				int opack_complete = (txgg & 3) == 2;
				int udp_oflag = (txgg & 2) == 2;
				// channel 0: data from simulation -> network
				int odata = (top->cluster_out >> (jx*8)) & 0xff;
				if (udp_oflag) {
					udp_sender_r(udp_states[jx], odata, opack_complete);
				}
			}
			top->cluster_in = client_xx;
		}

		// Evaluate model
		top->eval();

		// Process two special results
		n_lat = top->n_lat_expose;
		assert(n_lat > 0);
		cluster_n = top->cluster_n_expose;
		assert(cluster_n > 0);
		// Initialization
		if (udp_states == NULL) {
			udp_states = (udp_state**) malloc(cluster_n * sizeof(udp_state*));
			assert(udp_states);
			for (unsigned jx=0; jx<cluster_n; jx++) {
				int udp_port_ = udp_port_base + jx;
				printf("udp init %u udp_port %d\n", jx, udp_port_);
				udp_states[jx] = udp_setup_r(udp_port_, badger_client_);
			}
		}
		// Initialization
		if (txg_shifts == NULL) {
			txg_shifts = (int *) malloc(cluster_n * sizeof(int));
			assert(txg_shifts);
			for (unsigned jx=0; jx<cluster_n; jx++) {
				txg_shifts[jx] = 0;
			}
		}

		// Dump trace data for this cycle
		if (tfp) tfp->dump (main_time);
	}

	// Final model cleanup
	VL_PRINTF("Loop exit: interrupt_pending = %d\n", interrupt_pending);
	top->final();
	if (tfp) { tfp->close(); tfp = NULL; }

	// Coverage analysis (since test passed)
#if VM_COVERAGE
	Verilated::mkdir("logs");
	VerilatedCov::write("logs/coverage.dat");
#endif

	// Destroy model
	delete top;

	// Fin
	exit(0);
}
