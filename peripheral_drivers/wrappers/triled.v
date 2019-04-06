module triled (RED,GREEN,BLUE
,rgb);
output RED;
output GREEN;
output BLUE;
input [2:0] rgb;
assign {RED, GREEN, BLUE}=rgb;
endmodule
