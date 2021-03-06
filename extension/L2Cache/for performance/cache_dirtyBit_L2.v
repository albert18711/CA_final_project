module L2_Cache(
    clk,
    reset,
    // L1 side
    L2_read,
    L2_write,
    L2_addr,
    L2_rdata,
    L2_wdata,
    L2_ready,
    // mem side
    mem_read,
    mem_write,
    mem_addr,
    mem_rdata,
    mem_wdata,
    mem_ready,
    hittime,
    totaltime,
    stallcycle
);
    
//==== input/output definition ============================
    input           clk;
    input           reset;
    // L1 interface
    input           L2_read, L2_write;
    input   [27:0]  L2_addr;
    input   [127:0] L2_wdata;
    output          L2_ready;
    output  [127:0] L2_rdata;
    // memory interface
    input  [127:0] mem_rdata;
    input          mem_ready;
    output         mem_read, mem_write;
    output  [27:0] mem_addr;
    output [127:0] mem_wdata;
    
    output [50:0] hittime, totaltime, stallcycle;
    
    reg [50:0] hittime_r, hittime_w, totaltime_r, totaltime_w, stallcycle_r, stallcycle_w;
    
    assign hittime = hittime_r;
    assign totaltime = totaltime_r;
    assign stallcycle = stallcycle_r;

//==== wire/reg definition ================================
    // wire [1:0]  i_block_offset;
    // wire [24:0] i_tag;
    // wire [2:0]  i_cache_index;
    wire [22:0] i_tag;
    wire [4:0]  i_cache_index;
    
    reg L2_ready_reg;
    reg [127:0]  L2_rdata_reg;

    reg mem_read_r, mem_read_w;
    reg mem_write_r, mem_write_w;
    reg [27:0]  mem_addr_r, mem_addr_w;
    reg [127:0] mem_wdata_r, mem_wdata_w;

    reg         hit;
    // reg         hit_block   [0:7];
    
    reg         valid_bit_r [0:31];
    reg         valid_bit_w [0:31];
    reg         dirty_bit_r [0:31];
    reg         dirty_bit_w [0:31];
    reg [22:0]  tag_r       [0:31];
    reg [22:0]  tag_w       [0:31];
    reg [127:0] four_word_r [0:31];
    reg [127:0] four_word_w [0:31];

    // reg [31:0]  word_read;
    // reg [31:0]  word_write;

    // FSM
    reg [1:0] state_r, state_w;

    // for loop
    integer i;

    // debugging signals
    // reg [7:0] hit_block_debug;
    // reg [7:0] valid_bit_r_debug;
    // reg [199:0] tag_r_debug;
    // reg [1023:0] four_word_r_debug;
    // always @(*) begin
    //     for (i = 0; i < 8; i = i+1) begin
    //         // hit_block_debug[i] = hit_block[i];
    //         valid_bit_r_debug[i] = valid_bit_r[i];
    //         tag_r_debug[(199-i*25) -: 25] = tag_r[i];
    //         four_word_r_debug[(1023-i*128) -: 128] = four_word_r[i];
    //     end
    // end

    // reg [31:0] miss_counter_r, miss_counter_w;

//======== debug ======================

always@(*) begin
    if(reset) hittime_w = 0;
    else if(hit) hittime_w = hittime_r + 1;
    else hittime_w = hittime_r;
end

always@(*) begin
    if(reset) totaltime_w <= 0;
    else if(L2_read || L2_write) begin
        // if(~L2_ready) totaltime_w = totaltime_r + 1;
        // else totaltime_w = totaltime_r;
        totaltime_w = totaltime_r + 1;
    end else begin
        totaltime_w = totaltime_r;
    end
end

always@(*) begin
    if(reset) stallcycle_w = 0;
    // else if(mem_write || mem_read) stallcycle_w = stallcycle_r + 1;
    else if(~L2_read) stallcycle_w = stallcycle_r + 1;
    else stallcycle_w = stallcycle_r;
end

always@(posedge clk or posedge reset) begin
    if(reset) begin
        hittime_r <= 0;
        totaltime_r <= 0;
        stallcycle_r <= 0;
    end else begin
        hittime_r <= hittime_w;
        totaltime_r <= totaltime_w;
        stallcycle_r <= stallcycle_w;
    end
end

//==== combinational circuit ==============================
    parameter S_HIT  = 0;
    parameter S_MISS = 1;

    /////// proc input partition /////////////
    // assign i_block_offset = proc_addr[1:0];
    assign i_cache_index = L2_addr[4:0];
    assign i_tag = L2_addr[27:5];

    /////// output connection ////////////////
    assign L2_rdata = L2_rdata_reg;
    assign L2_ready = L2_ready_reg;

    assign mem_read = mem_read_r;
    assign mem_write = mem_write_r;
    assign mem_wdata = mem_wdata_r;
    assign mem_addr = mem_addr_r;
    // assign miss_counter = miss_counter_r;

    /////// FSM //////////////////////////////
    always @(*) begin
        state_w = state_r;
        L2_ready_reg = 1;
        L2_rdata_reg = 0;
        mem_read_w = mem_read_r;
        mem_write_w = mem_write_r;
        mem_wdata_w = mem_wdata_r;
        mem_addr_w = mem_addr_r;
        // miss_counter_w = miss_counter_r;

        // word_write = 0;
        for (i = 0; i < 31; i = i+1) begin
            tag_w[i] = tag_r[i];
            valid_bit_w[i] = valid_bit_r[i];
            four_word_w[i] = four_word_r[i];
            dirty_bit_w[i] = dirty_bit_r[i];
        end

        case (state_r)
            S_HIT: begin
                if(~hit) begin
                    state_w = S_MISS;
                    L2_ready_reg = 0;
                    // miss_counter_w = miss_counter_r + 1;
                    if(valid_bit_r[i_cache_index] & dirty_bit_r[i_cache_index]) begin
                        mem_read_w = 0;
                        mem_write_w = 1;
                        mem_addr_w = {tag_r[i_cache_index], i_cache_index};
                        mem_wdata_w = four_word_r[i_cache_index];
                    end
                    else begin
                        mem_read_w = 1;
                        mem_write_w = 0;
                        mem_addr_w = L2_addr[27:0];
                    end
                end
                else begin
                    state_w = S_HIT;
                    L2_ready_reg = 1;
                    if(L2_read && ~L2_write) begin
                        // proc_rdata_reg = word_read;
                        L2_rdata_reg = four_word_r[i_cache_index];
                        // case (i_block_offset)
                        //     0: proc_rdata_reg = four_word_r[i_cache_index][31:0];
                        //     1: proc_rdata_reg = four_word_r[i_cache_index][63:32];
                        //     2: proc_rdata_reg = four_word_r[i_cache_index][95:64];
                        //     3: proc_rdata_reg = four_word_r[i_cache_index][127:96];
                        //     default : /* default */;
                        // endcase
                    end
                    else if(~L2_read && L2_write) begin
                        // word_write = proc_wdata;
                        four_word_w[i_cache_index] = L2_wdata;
                        // case (i_block_offset)
                        //     0: four_word_w[i_cache_index][31:0] = proc_wdata;
                        //     1: four_word_w[i_cache_index][63:32] = proc_wdata;
                        //     2: four_word_w[i_cache_index][95:64] = proc_wdata;
                        //     3: four_word_w[i_cache_index][127:96] = proc_wdata;
                        //     default : /* default */;
                        // endcase
                        dirty_bit_w[i_cache_index] = 1;
                    end
                end
            end
            S_MISS: begin
                L2_ready_reg = 0;
                if(mem_ready) begin
                    mem_read_w = 0;
                    mem_write_w = 0;
                    if(mem_write_r && ~mem_read_r) begin
                        state_w = S_MISS;
                        mem_addr_w = L2_addr[27:0];
                        mem_write_w = 0;
                        mem_read_w = 1;
                    end
                    else begin
                        tag_w[i_cache_index] = i_tag;
                        four_word_w[i_cache_index] = mem_rdata;
                        valid_bit_w[i_cache_index] = 1;
                        state_w = S_HIT;
                    end
                end
            end
            default : /* default */;
        endcase
    end



    /////// read data ////////////////////////
    
    // block offset & block index pick
    // always @(*) begin
    //     word_read = 0;
    //     for (i = 0; i < 8; i = i+1) begin
    //         four_word_w[i] = four_word_r[i];
    //     end
    //     if(hit) begin
    //         case (i_block_offset)
    //             0: word_read = four_word_r[i_cache_index][31:0];
    //             1: word_read = four_word_r[i_cache_index][63:32];
    //             2: word_read = four_word_r[i_cache_index][95:64];
    //             3: word_read = four_word_r[i_cache_index][127:96];
    //             default : /* default */;
    //         endcase

    //         case (i_block_offset)
    //             0: four_word_w[i_cache_index][31:0] = word_write;
    //             1: four_word_w[i_cache_index][63:32] = word_write;
    //             2: four_word_w[i_cache_index][95:64] = word_write;
    //             3: four_word_w[i_cache_index][127:96] = word_write;
    //             default : /* default */;
    //         endcase
    //     end
    // end


    // hit specifiction
    always @(*) begin
        if(valid_bit_r[i_cache_index] == 1 && tag_r[i_cache_index] == i_tag) begin
            hit = 1;
        end
        else begin
            hit = 0;
        end
    end


//==== sequential circuit =================================
always@( posedge clk or posedge reset ) begin
    if( reset ) begin
        for (i = 0; i < 32; i = i+1) begin
            valid_bit_r[i] <= 0;
            tag_r[i] <= 0;
            four_word_r[i] <= 0;
            dirty_bit_r[i] <= 0;
        end
        mem_read_r <= 0;
        mem_write_r <= 0;
        mem_addr_r <= 0;
        mem_wdata_r <= 0;
        state_r <= S_HIT;
        // miss_counter_r <= 0;
    end
    else begin
        for (i = 0; i < 32; i = i+1) begin
            valid_bit_r[i] <= valid_bit_w[i];
            tag_r[i] <= tag_w[i];
            four_word_r[i] <= four_word_w[i];
            dirty_bit_r[i] <= dirty_bit_w[i];
        end
        state_r <= state_w;
        mem_write_r <= mem_write_w;
        mem_read_r <= mem_read_w;
        mem_addr_r <= mem_addr_w;
        mem_wdata_r <= mem_wdata_w;
        // miss_counter_r <= miss_counter_w;
    end
end

endmodule
