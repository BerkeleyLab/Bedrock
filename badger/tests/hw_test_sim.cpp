// Partially based on Verilator example module
#include <verilated.h>

// Include model header, generated from Verilating "hw_test.v"
#include "Vhw_test.h"
#include <verilated_vcd_c.h>
#include "ethernet_model.h"

// Current simulation time (64-bit unsigned)
vluint64_t main_time = 0;
// Called by $time in Verilog
double sc_time_stamp() {
	return main_time;  // Note does conversion to real, to match SystemC
}

int main(int argc, char** argv, char** env) {

	Verilated::commandArgs(argc, argv);
	Verilated::debug(0);

	Vhw_test* top = new Vhw_test;

	// Tracing (vcd)
	VerilatedVcdC* tfp = NULL;
	const char* flag = Verilated::commandArgsPlusMatch("trace");
	if (flag && 0==strcmp(flag, "+trace")) {
		Verilated::traceEverOn(true);
		// VL_PRINTF("Enabling waves into logs/vlt_dump.vcd...\n");
		tfp = new VerilatedVcdC;
		top->trace(tfp, 9);  // Trace 9 levels of hierarchy
		// Verilated::mkdir("logs");
		tfp->open("hw_test_sim.vcd");  // Open the dump file
	}

	// Set some inputs
	top->vgmii_rx_clk = 0;
	top->vgmii_rxd= 0;
	top->vgmii_rx_dv = 0;
	top->vgmii_rx_er = 0;
	top->vgmii_tx_clk = 0;
	top->SCLK = 0;
	top->CSB = 0;

	while (/* main_time < 1100 && */ !Verilated::gotFinish()) {
		main_time += 4;  // Time passes in ticks of 8ns
		// Toggle clocks and such
		top->vgmii_rx_clk = !top->vgmii_rx_clk;
		top->vgmii_tx_clk = top->vgmii_rx_clk;

		// Run Ethernet at falling edge of rx_clk
		if (top->vgmii_rx_clk==0) {
			int eth_in_hold, eth_in_s_hold;
			int r = ethernet_model(
				top->vgmii_txd, top->vgmii_tx_en,
				&eth_in_hold, &eth_in_s_hold,
				top->in_use);
			if (r==1) {  // Should never happen
				VL_PRINTF("Ethernet is dead\n");
				exit(1);
			}
			top->vgmii_rxd = eth_in_hold;
			top->vgmii_rx_dv = eth_in_s_hold;
		}

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
