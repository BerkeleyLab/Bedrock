// Based on firmware/prc/Vatb.cpp

#include <signal.h>
#include <verilated.h>

// Include model header, generated from Verilating
#include "Voscope_top.h"
#include <verilated_fst_c.h>


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

   Voscope_top* top = new Voscope_top;

   // Boilerplate to set up trapping of control-C
   struct sigaction sigIntHandler;
   sigIntHandler.sa_handler = interrupt_handler;
   sigemptyset(&sigIntHandler.sa_mask);
   sigIntHandler.sa_flags = 0;
   sigaction(SIGINT, &sigIntHandler, NULL);

   // Tracing (fst)
   VerilatedFstC* tfp = NULL;
   const char* flag = Verilated::commandArgsPlusMatch("trace");
   if (flag && 0==strcmp(flag, "+trace")) {
      Verilated::traceEverOn(true);
      tfp = new VerilatedFstC;
      top->trace(tfp, 5, 0);  // Trace 5 levels of hierarchy
      tfp->open("Voscope_top.vcd");
   }

   // Determine UDP port number from command line options
   udp_port = 3010;
   badger_client = 0;  // Raw interface
   const char* udp_arg = Verilated::commandArgsPlusMatch("udp_port=");
   if (strlen(udp_arg) > 1) {
      udp_port = atoi(udp_arg);
   }

   // Set initial state
   vluint32_t tick = 0;
   CData * sim_adc_clk = &(top->oscope_top__DOT__application_top__DOT__sim_adc_clk);
   CData * sim_sys_clk = &(top->oscope_top__DOT__sim_sys_clk);
   *sim_adc_clk = 0;
   *sim_sys_clk = 0;

   while (!Verilated::gotFinish() && !interrupt_pending) {
      main_time += 1;  // Time passes in ticks of 2 ns
      if (main_time % 3 == 0) {
         *sim_sys_clk = !*sim_sys_clk;
      }
      if (main_time % 2 == 0) {
         *sim_adc_clk = !*sim_adc_clk;
      }

      // Run UDP at falling edge of clk
      if (*sim_sys_clk==0 && (main_time % 3) == 0) {
         tick += 1;

         // Data from network -> simulation

         int udp_idata, udp_iflag, udp_count, thinking;
         // Throttle TX so it works with all generations of jxj_gate
         if (tick % 9 == 0) {
            udp_receiver(&udp_idata, &udp_iflag, &udp_count, thinking);
            top->oscope_top__DOT__p_50006_word_s6tok7_r = udp_idata;
            top->oscope_top__DOT__p_50006_rx_available_r = udp_iflag;
            top->oscope_top__DOT__p_50006_rx_complete_r = udp_count==1;

         } else {
            top->oscope_top__DOT__p_50006_rx_available_r = 0;
            top->oscope_top__DOT__p_50006_rx_complete_r = 0;
         }

         // Data from simulation -> network
         top->oscope_top__DOT__p_50006_word_read_r = 0;
         if ((tick+2) % 9 == 0) {
            if (top->oscope_top__DOT__p_50006_tx_available_r) {
                top->oscope_top__DOT__p_50006_word_read_r = 1;
               udp_sender(top->oscope_top__DOT__p_50006_word_k7tos6_r,
                          top->oscope_top__DOT__p_50006_tx_complete_r);
            }
         }
      }

      // Evaluate model
      top->eval();

      // Dump trace data for this cycle
      if (tfp) tfp->dump (main_time);
   }

   // Final model cleanup
   VL_PRINTF("Simulation loop exit: interrupt_pending = %d\n", interrupt_pending);
   VL_PRINTF("Not a self-checking testbench, will always PASS\n");
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
