`include "i_MIPS.v"
`include "cache_dirtyBit.v"
`include "L2cache_FIFObuffer2.v"
// Top module of your design, you cannot modify this module!!
module CHIP (	clk,
				rst_n,
//----------for slow_memD------------
				mem_read_D,
				mem_write_D,
				mem_addr_D,
				mem_wdata_D,
				mem_rdata_D,
				mem_ready_D,
//----------for slow_memI------------
				mem_read_I,
				mem_write_I,
				mem_addr_I,
				mem_wdata_I,
				mem_rdata_I,
				mem_ready_I,
//----------for TestBed--------------				
				DCACHE_addr, 
				DCACHE_wdata,
				DCACHE_wen   
			);
input			clk, rst_n;
//--------------------------

output			mem_read_D;
output			mem_write_D;
output	[31:4]	mem_addr_D;
output	[127:0]	mem_wdata_D;
input	[127:0]	mem_rdata_D;
input			mem_ready_D;
//--------------------------
output			mem_read_I;
output			mem_write_I;
output	[31:4]	mem_addr_I;
output	[127:0]	mem_wdata_I;
input	[127:0]	mem_rdata_I;
input			mem_ready_I;
//----------for TestBed--------------
output	[29:0]	DCACHE_addr;
output	[31:0]	DCACHE_wdata;
output			DCACHE_wen;
//--------------------------

// wire declaration
wire        ICACHE_ren;
wire        ICACHE_wen;
wire [29:0] ICACHE_addr;
wire [31:0] ICACHE_wdata;
wire        ICACHE_stall;
wire [31:0] ICACHE_rdata;

wire        DCACHE_ren;
wire        DCACHE_wen;
wire [29:0] DCACHE_addr;
wire [31:0] DCACHE_wdata;
wire        DCACHE_stall;
wire [31:0] DCACHE_rdata;

// L2
wire			mem_read_D_L2;
wire			mem_write_D_L2;
wire	[27:0]	mem_addr_D_L2;
wire	[127:0]	mem_wdata_D_L2;
wire	[127:0]	mem_rdata_D_L2;
wire			mem_ready_D_L2;
//--------------------------
wire			mem_read_I_L2;
wire			mem_write_I_L2;
wire	[27:0]	mem_addr_I_L2;
wire	[127:0]	mem_wdata_I_L2;
wire	[127:0]	mem_rdata_I_L2;
wire			mem_ready_I_L2;


//=========================================
	// Note that the overall design of your MIPS includes:
	// 1. pipelined MIPS processor
	// 2. data cache
	// 3. instruction cache


	MIPS_Pipeline i_MIPS(
		// control interface
		clk, 
		rst_n,
//----------I cache interface-------		
		ICACHE_ren,
		ICACHE_wen,
		ICACHE_addr,
		ICACHE_wdata,
		ICACHE_stall,
		ICACHE_rdata,
//----------D cache interface-------
		DCACHE_ren,
		DCACHE_wen,
		DCACHE_addr,
		DCACHE_wdata,
		DCACHE_stall,
		DCACHE_rdata
	);
	
	cache D_cache(
		clk,
		~rst_n,
		DCACHE_ren,
		DCACHE_wen,
		DCACHE_addr,
		DCACHE_wdata,
		DCACHE_stall,
		DCACHE_rdata,
		mem_read_D_L2,
		mem_write_D_L2,
		mem_addr_D_L2,
		mem_rdata_D_L2,
		mem_wdata_D_L2,
		mem_ready_D_L2
	);

	cache I_cache(
		clk,
		~rst_n,
		ICACHE_ren,
		ICACHE_wen,
		ICACHE_addr,
		ICACHE_wdata,
		ICACHE_stall,
		ICACHE_rdata,
		mem_read_I_L2,
		mem_write_I_L2,
		mem_addr_I_L2,
		mem_rdata_I_L2,
		mem_wdata_I_L2,
		mem_ready_I_L2
	);

	L2_Cache I_CL2 (
		clk,
		~rst_n,
		// L1 side
		mem_read_I_L2,
		mem_write_I_L2,
		mem_addr_I_L2,
		mem_rdata_I_L2,
		mem_wdata_I_L2,
		mem_ready_I_L2,
		// mem side
		mem_read_I,
		mem_write_I,
		mem_addr_I,
		mem_rdata_I,
		mem_wdata_I,
		mem_ready_I
	);

	L2_Cache D_CL2 (
		clk,
		~rst_n,
		// L1 side
		mem_read_D_L2,
		mem_write_D_L2,
		mem_addr_D_L2,
		mem_rdata_D_L2,
		mem_wdata_D_L2,
		mem_ready_D_L2,
		// mem side
		mem_read_D,
		mem_write_D,
		mem_addr_D,
		mem_rdata_D,
		mem_wdata_D,
		mem_ready_D
	);
	
endmodule

