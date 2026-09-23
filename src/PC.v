module PC (
    input wire clk,
    input wire rstn,    // Asynchronous Active low reset
    input wire [`LOG2_PMEMDEPTH-1:0] Next_PC_val,   // Comes from Write back stage once done one instruction

    output reg [`LOG2_PMEMDEPTH-1:0] PC_val     // Goes to Instruction memory
);

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        PC_val <= 'b0;
    end
    else begin
        PC_val <= Next_PC_val;
    end
end
    
endmodule