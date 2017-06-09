module ForwardUnit(
//i/p
    iRs_RegD,
    iRt_RegD,
    iRegWrite_RegE,
    iwsel_RegE,
    iRegWrite_RegM,
    iwsel_RegM,
//o/p
    oFU_ASel,
    oFU_BSel
);

input [4:0] iRs_RegD;
input [4:0] iRt_RegD;
input       iRegWrite_RegE;
input [4:0] iwsel_RegE;
input       iRegWrite_RegM;
input [4:0] iwsel_RegM;

output reg [1:0] oFU_ASel;
output reg [1:0] oFU_BSel;

wire forwardA, forwardB;

assign forwardA = (iRs_RegD == 0)? 0 : 1;
assign forwardB = (iRt_RegD == 0)? 0 : 1;

always@ (*) begin//A
    oFU_ASel = 2'b00;
	if((iRs_RegD == iwsel_RegE) & forwardA & iRegWrite_RegE)//1
        oFU_ASel = 2'b10;
    else if((iRs_RegD == iwsel_RegM) & forwardA & iRegWrite_RegM)//2
        oFU_ASel = 2'b01;
end

always@ (*) begin//B
    oFU_BSel = 2'b00;
	if((iRt_RegD == iwsel_RegE) & forwardB & iRegWrite_RegE)//1
        oFU_BSel = 2'b10;
    else if((iRt_RegD == iwsel_RegM) & forwardB & iRegWrite_RegM)//2
        oFU_BSel = 2'b01;
end

endmodule // ForwardUnit