interface zest_if (
   inout  [0:0]  U27,
   inout  [38:0] U4,
   inout  [6:0]  U1,
   inout  [26:0] U2,
   inout  [26:0] U3,
   inout  [3:0]  U15,
   inout  [4:0]  U18,
   inout  [7:0]  J17,
   inout  [7:0]  J18,
   inout  [11:0] J19,
   inout  [1:0]  U33U1
);

   // U27: Level translator
   wire U27_dir;
   assign U27[0] = U27_dir;

   // U1
   wire U1_CLKOUT3_INV = U1[0];
   wire U1_CLKOUT3     = U1[4];
   wire U1_DATAUWIRE;
   wire U1_LEUWIRE;
   assign U1[5] = U1_LEUWIRE;
   //assign U4[0] = U1_DATAUWIRE; // Use U4_SDIO instead

   // U2, U3: Fast ADC
   wire U2_D0NA, U2_D0NB, U2_D0NC, U2_D0ND, U2_D0PA, U2_D0PB, U2_D0PC, U2_D0PD,
        U2_D1NA, U2_D1NB, U2_D1NC, U2_D1ND, U2_D1PA, U2_D1PB, U2_D1PC, U2_D1PD,
        U2_DCON, U2_DCOP, U2_FCON, U2_FCOP;
   wire U2_PDWN, U2_CSB, U2_SCLK;

   assign {U2_D0NA, U2_D0NB, U2_D0NC, U2_D0ND} = {U2[16], U2[13], U2[23], U2[25]};
   assign {U2_D0PA, U2_D0PB, U2_D0PC, U2_D0PD} = {U2[20], U2[18], U2[24], U2[19]};
   assign {U2_D1NA, U2_D1NB, U2_D1NC, U2_D1ND} = {U2[14], U2[4],  U2[26], U2[11]};
   assign {U2_D1PA, U2_D1PB, U2_D1PC, U2_D1PD} = {U2[17], U2[8],  U2[5],  U2[12]};
   assign {U2_DCON, U2_DCOP, U2_FCON, U2_FCOP} = {U2[9],  U2[15], U2[10], U2[6]};
   assign {U3[10], U2[22], U4[26]} = {U2_PDWN, U2_CSB, U2_SCLK};

   wire U3_D0NA, U3_D0NB, U3_D0NC, U3_D0ND, U3_D0PA, U3_D0PB, U3_D0PC, U3_D0PD,
        U3_D1NA, U3_D1NB, U3_D1NC, U3_D1ND, U3_D1PA, U3_D1PB, U3_D1PC, U3_D1PD,
        U3_DCON, U3_DCOP, U3_FCON, U3_FCOP;
   wire U3_PDWN, U3_CSB;
   wire U3_SDIO;

   assign {U3_D0NA, U3_D0NB, U3_D0NC, U3_D0ND} = {U3[16], U3[13], U3[12], U3[7]};
   assign {U3_D0PA, U3_D0PB, U3_D0PC, U3_D0PD} = {U3[18], U3[25], U3[19], U3[9]};
   assign {U3_D1NA, U3_D1NB, U3_D1NC, U3_D1ND} = {U3[5],  U3[6],  U3[3],  U3[26]};
   assign {U3_D1PA, U3_D1PB, U3_D1PC, U3_D1PD} = {U3[8],  U3[23], U3[22], U3[14]};
   assign {U3_DCON, U3_DCOP, U3_FCON, U3_FCOP} = {U3[4],  U3[24], U3[15], U3[20]};
   assign {U3[10], U3[11]} = {U3_PDWN, U3_CSB};

   // U4: Fast DAC
   wire U4_D0N, U4_D0P, U4_D1N, U4_D1P, U4_D2N, U4_D2P, U4_D3N, U4_D3P,
        U4_D4N, U4_D4P, U4_D5N, U4_D5P, U4_D6N, U4_D6P, U4_D7N, U4_D7P,
        U4_D8N, U4_D8P, U4_D9N, U4_D9P, U4_D10N, U4_D10P, U4_D11N, U4_D11P,
        U4_D12N, U4_D12P, U4_D13N, U4_D13P,
        U4_DCIN, U4_DCIP, U4_RESET, U4_CSB, U4_SDIO;
   wire U4_DCON, U4_DCOP, U4_SDO;

   assign {U4[7],  U4[25], U4[34], U4[14]} = {U4_D0N,  U4_D0P,  U4_D1N,  U4_D1P};
   assign {U4[5],  U4[16], U4[11], U4[33]} = {U4_D2N,  U4_D2P,  U4_D3N,  U4_D3P};
   assign {U4[15], U4[36], U4[18], U4[20]} = {U4_D4N,  U4_D4P,  U4_D5N,  U4_D5P};
   assign {U4[4],  U4[27], U4[21], U4[3]}  = {U4_D6N,  U4_D6P,  U4_D7N,  U4_D7P};
   assign {U4[24], U4[30], U4[32], U4[35]} = {U4_D8N,  U4_D8P,  U4_D9N,  U4_D9P};
   assign {U4[28], U4[9],  U4[22], U4[38]} = {U4_D10N, U4_D10P, U4_D11N, U4_D11P};
   assign {U4[6],  U4[23], U4[17], U4[31]} = {U4_D12N, U4_D12P, U4_D13N, U4_D13P};
   assign {U4[10], U4[29], U4[8], U4[19], U4[0]} = {U4_DCIN, U4_DCIP, U4_RESET, U4_CSB, U4_SDIO};
   assign {U4_DCON, U4_DCOP, U4_SDO} = {U4[37], U4[13], U4[12]};

   // U15: Monitoring ADC/DAC
   wire U15_SS;
   wire U15_MISO = U15[1];
   assign U15[2] = U15_SS;

   // U18: Thermometer
   wire U18_CLK, U18_CS, U18_DIN, U18_SCLK;
   wire U18_DOUT_RDY = U18[1];
   assign {U18[0], U18[2], U18[3], U18[4]} = {U18_CLK, U18_CS, U18_DIN, U18_SCLK};

   // NOTE: Semantics of PMOD and HDMI connectors are application dependent and
   //       thus not handled here
   // PMOD - J18, J17
   // J19: HDMI

   // U33U1: DC-DC converter
   wire U33U1_pwr_sync, U33U1_pwr_en;
   assign {U33U1[1], U33U1[0]} = {U33U1_pwr_en, U33U1_pwr_sync};

   modport carrier (
      // LMK01801
      input U1_CLKOUT3_INV, U1_CLKOUT3,
      output U1_DATAUWIRE, U1_LEUWIRE,
      // NXP_74AVC4T245
      output U27_dir,
      // AD9653
      input  U2_D0NA, U2_D0NB, U2_D0NC, U2_D0ND, U2_D0PA, U2_D0PB, U2_D0PC, U2_D0PD,
             U2_D1NA, U2_D1NB, U2_D1NC, U2_D1ND, U2_D1PA, U2_D1PB, U2_D1PC, U2_D1PD,
             U2_DCON, U2_DCOP, U2_FCON, U2_FCOP,
      output U2_PDWN, U2_CSB, U2_SCLK,
      input  U3_D0NA, U3_D0NB, U3_D0NC, U3_D0ND, U3_D0PA, U3_D0PB, U3_D0PC, U3_D0PD,
             U3_D1NA, U3_D1NB, U3_D1NC, U3_D1ND, U3_D1PA, U3_D1PB, U3_D1PC, U3_D1PD,
             U3_DCON, U3_DCOP, U3_FCON, U3_FCOP,
      output U3_PDWN, U3_CSB,
      // AD9781
      output U4_D0N, U4_D0P, U4_D1N, U4_D1P, U4_D2N, U4_D2P, U4_D3N, U4_D3P,
             U4_D4N, U4_D4P, U4_D5N, U4_D5P, U4_D6N, U4_D6P, U4_D7N, U4_D7P,
             U4_D8N, U4_D8P, U4_D9N, U4_D9P, U4_D10N, U4_D10P, U4_D11N, U4_D11P,
             U4_D12N, U4_D12P, U4_D13N, U4_D13P,
             U4_DCIN, U4_DCIP, U4_RESET, U4_CSB, U4_SDIO,
      input  U4_DCON, U4_DCOP, U4_SDO,
      inout  U4, // To expose U4[1] bi-dir port
      // AMC7823
      output U15_SS, input U15_MISO,
      // AD7794
      output U18_CLK, U18_CS, U18_DIN, U18_SCLK, input U18_DOUT_RDY,
      // TPS62110
      output U33U1_pwr_en, U33U1_pwr_sync);

endinterface
