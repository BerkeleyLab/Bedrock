module hdmi (output CEC,output CKP, output CKN,output D0N,output D0P,output D1N,output D1P,output D2N,output D2P,output DET,output SCL,output SDA,input [5:0] hdmi_data, input [5:0] hdmi_ctrl);
assign {D0P,D0N,D1P,D1N,D2P,D2N}=hdmi_data;
assign {CEC,CKP,CKN,SCL,SDA,DET}=hdmi_ctrl;
// pin   CEC is     IO_L7P_T1_D09_14 bank  14 bus_digitizer_J19[1]        D21
// pin   CKN is     IO_L8N_T1_D12_14 bank  14 bus_digitizer_J19[11]        A20
// pin   CKP is     IO_L8P_T1_D11_14 bank  14 bus_digitizer_J19[4]        B20
// pin   D0N is     IO_L2N_T0_D03_14 bank  14 bus_digitizer_J19[8]        A22
// pin   D0P is     IO_L2P_T0_D02_14 bank  14 bus_digitizer_J19[2]        B22
// pin   D1N is     IO_L4N_T0_D05_14 bank  14 bus_digitizer_J19[10]        A24
// pin   D1P is     IO_L4P_T0_D04_14 bank  14 bus_digitizer_J19[0]        A23
// pin   D2N is IO_L6N_T0_D08_VREF_14 bank  14 bus_digitizer_J19[5]        C24
// pin   D2P is   IO_L6P_T0_FCS_B_14 bank  14 bus_digitizer_J19[7]        C23
// pin   DET is    IO_L10N_T1_D15_14 bank  14 bus_digitizer_J19[9]        B21
// pin   SCL is     IO_L7N_T1_D10_14 bank  14 bus_digitizer_J19[6]        C22
// pin   SDA is    IO_L10P_T1_D14_14 bank  14 bus_digitizer_J19[3]        C21
endmodule
