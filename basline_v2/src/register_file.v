module register_file(
    Clk  ,
	rst  ,
    WEN  ,
    RW   ,
    busW ,
    RX   ,
    RY   ,
    busX ,
    busY
);
    input        Clk, WEN, rst;
    input  [4:0] RW, RX, RY;
    input  [31:0] busW;
    output reg [31:0] busX, busY;
    
    // write your design here
    reg [31:0] register [0:31];

always @ (*) begin
	//register[0] = 0; //not sure where to put it...
	if(RX == RW && RX != 0) begin
		busX = busW;
	end
	else begin
		case(RX)
			1: busX = register[1];
			2: busX = register[2];
			3: busX = register[3];
			4: busX = register[4];
			5: busX = register[5];
			6: busX = register[6];
			7: busX = register[7];
			8: busX = register[8];
			9: busX = register[9];
			10: busX = register[10];
			11: busX = register[11];
			12: busX = register[12];
			13: busX = register[13];
			14: busX = register[14];
			15: busX = register[15];
			16: busX = register[16];
			17: busX = register[17];
			18: busX = register[18];
			19: busX = register[19];
			20: busX = register[20];
			21: busX = register[21];
			22: busX = register[22];
			23: busX = register[23];
			24: busX = register[24];
			25: busX = register[25];
			26: busX = register[26];
			27: busX = register[27];
			28: busX = register[28];
			29: busX = register[29];
			30: busX = register[30];
			31: busX = register[31];
			default: busX = 0;
		endcase
	end
	if(RY == RW && RY != 0) begin
		busY = busW;
	end
	else begin
		case(RY)
			1: busY = register[1];
			2: busY = register[2];
			3: busY = register[3];
			4: busY = register[4];
			5: busY = register[5];
			6: busY = register[6];
			7: busY = register[7];
			8: busY = register[8];
			9: busY = register[9];
			10: busY = register[10];
			11: busY = register[11];
			12: busY = register[12];
			13: busY = register[13];
			14: busY = register[14];
			15: busY = register[15];
			16: busY = register[16];
			17: busY = register[17];
			18: busY = register[18];
			19: busY = register[19];
			20: busY = register[20];
			21: busY = register[21];
			22: busY = register[22];
			23: busY = register[23];
			24: busY = register[24];
			25: busY = register[25];
			26: busY = register[26];
			27: busY = register[27];
			28: busY = register[28];
			29: busY = register[29];
			30: busY = register[30];
			31: busY = register[31];
			default: busY = 0;
		endcase
	end	
end
	
	
always @ (posedge Clk) begin
	if(~rst) begin
		register[0] <= 0;
		register[1] <= 0;
		register[2] <= 0;
		register[3] <= 0;
		register[4] <= 0;
		register[5] <= 0;
		register[6] <= 0;
		register[7] <= 0;
		register[8] <= 0;
		register[9] <= 0;
		register[10] <= 0;
		register[11] <= 0;
		register[12] <= 0;
		register[13] <= 0;
		register[14] <= 0;
		register[15] <= 0;
		register[16] <= 0;
		register[17] <= 0;
		register[18] <= 0;
		register[19] <= 0;
		register[20] <= 0;
		register[21] <= 0;
		register[22] <= 0;
		register[23] <= 0;
		register[24] <= 0;
		register[25] <= 0;
		register[26] <= 0;
		register[27] <= 0;
		register[28] <= 0;
		register[29] <= 0;
		register[30] <= 0;
		register[31] <= 0;	
	end
	else if(WEN) begin
		case(RW)
			1: register[1] <= busW;
			2: register[2] <= busW;
			3: register[3] <= busW;
			4: register[4] <= busW;
			5: register[5] <= busW;
			6: register[6] <= busW;
			7: register[7] <= busW;
			8: register[8] <= busW;
			9: register[9] <= busW;
			10: register[10] <= busW;
			11: register[11] <= busW;
			12: register[12] <= busW;
			13: register[13] <= busW;
			14: register[14] <= busW;
			15: register[15] <= busW;
			16: register[16] <= busW;
			17: register[17] <= busW;
			18: register[18] <= busW;
			19: register[19] <= busW;
			20: register[20] <= busW;
			21: register[21] <= busW;
			22: register[22] <= busW;
			23: register[23] <= busW;
			24: register[24] <= busW;
			25: register[25] <= busW;
			26: register[26] <= busW;
			27: register[27] <= busW;
			28: register[28] <= busW;
			29: register[29] <= busW;
			30: register[30] <= busW;
			31: register[31] <= busW;
			default: register[0] <= 0; //need it here or not?
		endcase
	end else begin
		register[0] <= register[0];
		register[1] <= register[1];
		register[2] <= register[2];
		register[3] <= register[3];
		register[4] <= register[4];
		register[5] <= register[5];
		register[6] <= register[6];
		register[7] <= register[7];
		register[8] <= register[8];
		register[9] <= register[9];
		register[10] <= register[10];
		register[11] <= register[11];
		register[12] <= register[12];
		register[13] <= register[13];
		register[14] <= register[14];
		register[15] <= register[15];
		register[16] <= register[16];
		register[17] <= register[17];
		register[18] <= register[18];
		register[19] <= register[19];
		register[20] <= register[20];
		register[21] <= register[21];
		register[22] <= register[22];
		register[23] <= register[23];
		register[24] <= register[24];
		register[25] <= register[25];
		register[26] <= register[26];
		register[27] <= register[27];
		register[28] <= register[28];
		register[29] <= register[29];
		register[30] <= register[30];
		register[31] <= register[31];
	end
end	
	
endmodule
