// ------------------------------------
// chitchat_pack.vh
// Shared constants for Chitchat IP
// ------------------------------------

localparam [3:0] CC_PROTOCOL_CAT = 4'h6;
localparam [3:0] CC_PROTOCOL_VER = 4'h1;
localparam [7:0] CC_K28_5 = 8'b10111100;
localparam LINK_UP_CNT = 4; // Number of consecutive frames until link is deemed up
localparam WORD_FRAME_CNT = 11;  // Number of WORD (excluded CRC) included in the frame
