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

wire common_condi_1;

assign common_condi_1 = (iwsel_RegE != 0);

always@ (*) begin//A
    oFU_ASel = 2'b00;
	if((iRs_RegD == iwsel_RegE) & common_condi_1 & iRegWrite_RegE)//1
        oFU_ASel = 2'b10;
    else if(iRegWrite_RegM &
            (iwsel_RegM != 0) &
            ~(iRegWrite_RegE & (iwsel_RegE != 0) & (iwsel_RegE != iRs_RegD)) &
            (iwsel_RegM == iRs_RegD)) //2
        oFU_ASel = 2'b01;
end

always@ (*) begin//B
    oFU_BSel = 2'b00;
	if((iRt_RegD == iwsel_RegE) & common_condi_1 & iRegWrite_RegE)//1
        oFU_BSel = 2'b10;
    else if(iRegWrite_RegM &
            (iwsel_RegM != 0) &
            ~(iRegWrite_RegE & (iwsel_RegE != 0) & (iwsel_RegE != iRt_RegD)) &
            (iwsel_RegM == iRt_RegD)) //2
        oFU_BSel = 2'b01;
end

endmodule // ForwardUnit