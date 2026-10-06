`include "../src/params.vh"

module L1_cache (
    input wire clk_cpu,
    input wire rstn_cpu,
    // CPU core side ports
    input wire cpu_req,
    input wire cpu_wen, cpu_ren, 
    input wire [(`ADDR_WIDTH)-1:0] cpu_addr,
    input wire [(`WIDTH)-1:0] cpu_wdata,
    output reg [(`WIDTH)-1:0] cpu_rdata,
    output reg cache_done,
    // Request FIFO side ports
    input wire req_full,
    output reg req_wr_en,
    output reg [(`FIFO_WIDTH)-1:0] req_wr_data,

    // Response FIFO side ports
    input wire resp_empty,
    output reg resp_rd_en,
    input wire [(`WIDTH)-1:0] resp_rd_data

);

// Cache Parameters:
localparam NofW = 4;
localparam CACHE_WIDTH = `WIDTH * NofW ; 
localparam NofL = 64;
localparam IDX = $clog2(NofL);
localparam TAGB = 6;
localparam OFFSET = 2;
localparam WORDS = 3'd4;

// Cache memory:
reg [CACHE_WIDTH-1:0] cache_mem [NofL-1:0];

// tag directory
reg [TAGB-1:0] tag_dir [NofL-1:0];
// Valid directory
reg Valid [NofL-1:0];
// Dirty Directory
reg Dirty [NofL-1:0];

// Temporary counter declaration
reg [1:0] w_cnt, r_cnt;

// Temporary registers
reg saved_wen, saved_ren;
reg [TAGB-1:0] saved_tag;
reg [IDX-1:0] saved_index;
reg [(`ADDR_WIDTH)-1:0] saved_addr;
reg [(`WIDTH)-1:0] saved_wdata, evict_data;
reg [(`ADDR_WIDTH)-1:0] evict_addr;
reg [OFFSET-1:0] saved_offset;
wire r_cnt3, w_cnt3;
integer i;

// Tag bit mapping
wire [TAGB-1:0] tag;
assign tag = cpu_addr[(`ADDR_WIDTH)-1:((`ADDR_WIDTH)-TAGB)];
// Index bit mapping
wire [IDX-1:0] index;
assign index = cpu_addr[(`ADDR_WIDTH-TAGB-1):(`ADDR_WIDTH-TAGB-IDX)];
// Offset bit mapping
wire [OFFSET-1:0] offset;
assign offset = cpu_addr[OFFSET-1:0];

// Hit logic
wire Hit;
assign Hit = Valid[index] && (tag_dir[index] == tag);

localparam IDLE = 3'd0,
           EVICT_REQ = 3'd1,
           FILL_REQ = 3'd2,
           FILL_WAIT = 3'd3,
           FILL_CACHE = 3'd4;

localparam WORD0 = 2'd0,
           WORD1 = 2'd1,
           WORD2 = 2'd2,
           WORD3 = 2'd3;

reg [2:0] PS, NS;

// Present State Logic
always @(posedge clk_cpu or negedge rstn_cpu ) begin
    if(!rstn_cpu) begin
        PS <= IDLE;
    end
    else begin
        PS <= NS;
    end
end

// Next State Logic
always @(*) begin
    case (PS)
        IDLE: NS = cpu_req ? (!Hit ? ((Valid[index] && Dirty[index]) ? EVICT_REQ : FILL_REQ) : IDLE) : IDLE;
        EVICT_REQ: NS = (!req_full && (w_cnt3)) ? FILL_REQ : EVICT_REQ;
        FILL_REQ: NS = !req_full ? FILL_WAIT : FILL_REQ;
        FILL_WAIT: NS = (!resp_empty) ? FILL_CACHE : FILL_WAIT;
        FILL_CACHE: NS = (r_cnt3) ? IDLE : FILL_CACHE;
        default: NS = IDLE;
    endcase
end

// Cache controller logic
always @(posedge clk_cpu or negedge rstn_cpu ) begin
    if (!rstn_cpu) begin
        cache_done <= 'd0;
        for (i = 0; i < NofL; i = i + 1) begin
            tag_dir[i] <= 'd0;
            Valid[i] <= 'd0;
            Dirty[i] <= 'd0;
            cache_mem[i] <= 'd0;
        end
        cpu_rdata <= 'd0;
        saved_wen <= 'd0;
        saved_ren <= 'd0;
        saved_tag <= 'd0;
        saved_index <= 'd0;
        saved_addr <= 'd0;
        saved_wdata <= 'd0;
        evict_addr <= 'd0;
        evict_data <= 'd0;
        req_wr_data <= 'd0;
        req_wr_en <= 'd0;
        w_cnt <= 'd0;
        r_cnt <= 'd0;
        saved_offset <= 'd0;
        resp_rd_en <= 'd0;
    end
    else begin
        case (PS)
            IDLE: begin
                cache_done <= 'd0;
                w_cnt <= 'd0;
                if (cpu_req) begin
                    if (Hit) begin
                        if (cpu_wen) begin
                            case (offset)
                                WORD0: cache_mem[index][CACHE_WIDTH-1:CACHE_WIDTH-(`WIDTH)] <= cpu_wdata;
                                WORD1: cache_mem[index][CACHE_WIDTH-(`WIDTH)-1:CACHE_WIDTH-(2*(`WIDTH))] <= cpu_wdata;
                                WORD2: cache_mem[index][CACHE_WIDTH-(2*(`WIDTH))-1:CACHE_WIDTH-(3*(`WIDTH))] <= cpu_wdata;
                                WORD3: cache_mem[index][CACHE_WIDTH-(3*(`WIDTH))-1:CACHE_WIDTH-(4*(`WIDTH))] <= cpu_wdata;
                                default: cache_mem[index] <= cache_mem[index];  // Nothing Happened
                            endcase
                            Valid[index] <= 1;
                            Dirty[index] <= Valid[index] ? 1 : 0;
                            tag_dir[index] <= tag;
                            cache_done <= 1'd1;
                        end
                        else if (cpu_ren && Valid[index]) begin
                            case (offset)
                                WORD0: cpu_rdata <= cache_mem[index][CACHE_WIDTH-1:CACHE_WIDTH-(`WIDTH)];
                                WORD1: cpu_rdata <= cache_mem[index][CACHE_WIDTH-(`WIDTH)-1:CACHE_WIDTH-(2*(`WIDTH))];
                                WORD2: cpu_rdata <= cache_mem[index][CACHE_WIDTH-(2*(`WIDTH))-1:CACHE_WIDTH-(3*(`WIDTH))];
                                WORD3: cpu_rdata <= cache_mem[index][CACHE_WIDTH-(3*(`WIDTH))-1:CACHE_WIDTH-(4*(`WIDTH))];
                                default: cpu_rdata <= cpu_rdata;  // Nothing Happened
                            endcase
                            cache_done <= 1'd1;
                        end
                    end
                end
            end 
            
            EVICT_REQ: begin
                cache_done <= 'd0;
                saved_wen <= cpu_wen;
                saved_ren <= cpu_ren;
                saved_tag <= tag;
                saved_index <= index;
                saved_addr <= cpu_addr;
                saved_wdata <= cpu_wdata;
                evict_addr <= {tag_dir[index], index, w_cnt};
                case (w_cnt)
                    WORD0: evict_data <= cache_mem[index][CACHE_WIDTH-1:CACHE_WIDTH-(`WIDTH)];
                    WORD1: evict_data <= cache_mem[index][CACHE_WIDTH-(`WIDTH)-1:CACHE_WIDTH-(2*(`WIDTH))];
                    WORD2: evict_data <= cache_mem[index][CACHE_WIDTH-(2*(`WIDTH))-1:CACHE_WIDTH-(3*(`WIDTH))];
                    WORD3: evict_data <= cache_mem[index][CACHE_WIDTH-(3*(`WIDTH))-1:CACHE_WIDTH-(4*(`WIDTH))];
                    default: evict_data <= evict_data;  // Nothing Happened
                endcase
                if (!req_full) begin
                    req_wr_data <= {1'd1, evict_addr, evict_data};
                    req_wr_en <= 1;
                    if (w_cnt3) begin
                        w_cnt <= 'b0;
                    end
                    else w_cnt <= w_cnt + 1;
                end
            end

            FILL_REQ: begin
                cache_done <= 'd0;
                saved_wen <= cpu_wen;
                saved_ren <= cpu_ren;
                saved_tag <= tag;
                saved_index <= index;
                saved_offset <= offset;
                saved_addr <= cpu_addr;
                saved_wdata <= cpu_wdata;
                if (!req_full) begin
                    req_wr_data <= {1'd0, cpu_addr, cpu_wdata};
                    req_wr_en <= 1;
                end
            end
            FILL_WAIT: begin
                cache_done <= 'd0;
                resp_rd_en <= 1;
                r_cnt <= 0;
            end
            FILL_CACHE: begin
                cache_done <= 'd0;
                if (r_cnt3) begin
                    r_cnt <= 0;
                end
                else if (!resp_empty) begin
                    r_cnt <= r_cnt + 1;
                end
                case (r_cnt)
                    WORD0: cache_mem[index][CACHE_WIDTH-1:CACHE_WIDTH-(`WIDTH)] <= resp_rd_data;
                    WORD1: cache_mem[index][CACHE_WIDTH-(`WIDTH)-1:CACHE_WIDTH-(2*(`WIDTH))] <= resp_rd_data;
                    WORD2: cache_mem[index][CACHE_WIDTH-(2*(`WIDTH))-1:CACHE_WIDTH-(3*(`WIDTH))] <= resp_rd_data;
                    WORD3: cache_mem[index][CACHE_WIDTH-(3*(`WIDTH))-1:CACHE_WIDTH-(4*(`WIDTH))] <= resp_rd_data;
                    default: cache_mem[index] <= cache_mem[index];  // Nothing Happened
                endcase
                if (r_cnt3) begin
                    case (saved_offset)
                        WORD0: cpu_rdata <= cache_mem[index][CACHE_WIDTH-1:CACHE_WIDTH-(`WIDTH)];
                        WORD1: cpu_rdata <= cache_mem[index][CACHE_WIDTH-(`WIDTH)-1:CACHE_WIDTH-(2*(`WIDTH))];
                        WORD2: cpu_rdata <= cache_mem[index][CACHE_WIDTH-(2*(`WIDTH))-1:CACHE_WIDTH-(3*(`WIDTH))];
                        WORD3: cpu_rdata <= resp_rd_data;
                        default: cpu_rdata <= cpu_rdata;  // Nothing Happened
                    endcase
                    Dirty[saved_index] <= 0;
                    Valid[index] <= 1;
                    cache_done <= 1;
                    resp_rd_en <= 0;
                end
            end
            default: begin
                cache_done <= cache_done;
                cpu_rdata <= cpu_rdata;
                saved_wen <= saved_wen;
                saved_ren <= saved_ren;
                saved_tag <= saved_tag;
                saved_index <= saved_index;
                saved_addr <= saved_addr;
                saved_wdata <= saved_wdata;
                evict_addr <= evict_addr;
                evict_data <= evict_data;
                req_wr_data <= req_wr_data;
                req_wr_en <= req_wr_en;
                w_cnt <= w_cnt;
                r_cnt <= r_cnt;
                saved_offset <= saved_offset;
                resp_rd_en <= resp_rd_en;
            end
        endcase

    end
end

// Count value assigning:
assign w_cnt3 = (w_cnt == WORDS-1);
assign r_cnt3 = (r_cnt == WORDS-1);
endmodule
