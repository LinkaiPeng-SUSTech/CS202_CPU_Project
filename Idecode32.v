module Idecode32(
    output [31:0] read_data_1,
    output [31:0] read_data_2,
    input[31:0]  Instruction,
    input[31:0]  read_data,
    input[31:0]  ALU_result,
    input        Jal,
    input        RegWrite,
    input        MemtoReg,
    input        RegDst,
    output[31:0] imme_extend,
    input        clock,
    input        reset,
    input[31:0]  opcplus4
);

wire[5:0] opcode= Instruction[31:26];
wire[4:0] rs= Instruction[25:21];
wire[4:0] rt = Instruction[20:16];
wire[4:0] rd= Instruction[15:11];
wire[15:0] immediate= Instruction[15:0];

reg[31:0] register[0:31];
reg[4:0] write_reg;
reg[31:0] write_data;

integer i;
always @(posedge clock) begin
    if(reset) begin
    for(i=0;i<=31;i=i+1) 
        register[i] <= 32'b0;
    end
    else begin
        write_reg = (6'b000011 == opcode && Jal)?5'b11111:(RegDst)?rd:rt;
        if((RegWrite || Jal) && write_reg != 0) begin
            register[write_reg] <= ((6'b000011 == opcode && 1'b1 == Jal)?opcplus4:(MemtoReg?read_data:ALU_result));
        end
    end
end

assign imme_extend = (6'b001100 == opcode || 6'b001101 == opcode)?{{16{1'b0}},immediate}:{{16{Instruction[15]}},immediate};
assign read_data_1 = register[rs];
assign read_data_2 = register[rt];

endmodule
