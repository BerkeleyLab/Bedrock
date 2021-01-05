// Partially based on Verilator example module
#include <verilated.h>

// Include model header, generated from Verilating "marble_base.v"
#include "Vmarble_base.h"
#include <verilated_fst_c.h>
#include "ethernet_model.h"

void spi_model(unsigned char *SCLK, unsigned char *CSB, unsigned char *MOSI, unsigned char MISO);

// Current simulation time (64-bit unsigned)
vluint64_t main_time = 0;
// Called by $time in Verilog
double sc_time_stamp() {
	return main_time;  // Note does conversion to real, to match SystemC
}

int main(int argc, char** argv, char** env) {

	Verilated::commandArgs(argc, argv);
	Verilated::debug(0);

	Vmarble_base* top = new Vmarble_base;

	// Tracing (vcd)
	VerilatedFstC* tfp = NULL;
	const char* flag = Verilated::commandArgsPlusMatch("trace");
	if (flag && 0==strcmp(flag, "+trace")) {
		Verilated::traceEverOn(true);
		// VL_PRINTF("Enabling waves into logs/vlt_dump.vcd...\n");
		tfp = new VerilatedFstC;
		top->trace(tfp, 9);  // Trace 9 levels of hierarchy
		// Verilated::mkdir("logs");
		tfp->open("marble_base_sim.vcd");  // Open the dump file
	}
	// Set some inputs
	top->vgmii_rx_clk = 0;
	top->vgmii_rxd= 0;
	top->vgmii_rx_dv = 0;
	top->vgmii_rx_er = 0;
	top->vgmii_tx_clk = 0;
	top->SCLK = 0;
	top->CSB = 1;
	top->MOSI = 0;

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
		// Run SPI on falling edge of tx_clk
		if (top->vgmii_tx_clk==0) {
			spi_model(&top->SCLK, &top->CSB, &top->MOSI, top->MISO);
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

void spi_model(unsigned char *SCLK, unsigned char *CSB, unsigned char *MOSI, unsigned char MISO)
{
	static struct {
		unsigned clk;
		unsigned word_ix;
		unsigned pattern_ix;
		uint16_t tx_word;
	} state = {0};
	static int cc=0;
	// Write "1234ABCD" to first half of page 3
	// this should show up at (Ethernet) local bus 2097200 - 2097207
	// End with two read instructions.  Should check correctness here.
	const uint16_t pattern[] = {0x2203, 0x50b1, 0x51b2, 0x52b3, 0x53b4, 0x5441, 0x5542, 0x5643, 0x5744, 0x4411, 0x4111};
	const unsigned pattern_len = sizeof(pattern) / sizeof(pattern[0]);
	static unsigned pattern_ix = 0;
	if (!SCLK || !CSB || !MOSI) {
		if (cc == 0) VL_PRINTF("spi_model() caller misconfigured\n");	
		cc++;
		return;
	}
	if (cc % 3 == 0) {
		state.clk = !state.clk;
		if (state.clk == 0) {
			*SCLK = 1;
			state.word_ix++;
			if (state.word_ix == 1) {
				if (state.pattern_ix < pattern_len) {
					*CSB = 0;
					state.tx_word = pattern[state.pattern_ix++];
				} else {
					state.tx_word = 0;
				}
			}
			*MOSI = (state.tx_word & 0x8000) != 0;
			state.tx_word = state.tx_word << 1;
			if (state.word_ix == 18) *CSB = 1;
			if (state.word_ix == 20) state.word_ix = 0;
		} else {
			if (state.word_ix > 0 && state.word_ix <= 16) *SCLK = 0;
		}
	}
	cc++;
}
