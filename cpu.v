`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/18 10:51:32
// Design Name: 
// Module Name: cpu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CPU_TOP(
input fpga_rst,
input fpga_clk,
input [23:0]switch2N4,
output [23:0]led2N4,
input start_pg,
input rx,
output tx
    );
// UART Programmer Pinouts 
wire upg_clk, upg_clk_o; 
wire upg_wen_o; //Uart write out enable 
wire upg_done_o; //Uart rx data have done 
//data to which memory unit of program_rom/dmemory32 
wire [14:0] upg_adr_o; //data to program_rom or dmemory32 
wire [31:0] upg_dat_o;
wire spg_bufg; 
BUFG U1(.clk(fpga_clk), .nrst(fpga_rst), .key_in(start_pg), .key_out(spg_bufg)); // de-twitter 
// Generate UART Programmer reset signal 
reg upg_rst; 
always @ (posedge fpga_clk) 
begin 
    if (spg_bufg) 
        upg_rst = 0; 
    if (fpga_rst) 
        upg_rst = 1; 
end
wire rst = fpga_rst | !upg_rst;

cpuclk clk(.clk_in1(fpga_clk), .clk_out1(upg_clk),.clk_out2(upg_clk_o));
//////////////////////////////////23                10

//uart的wires
wire upg_clk_w; //链接dmemory32
wire upg_wen_w; //链接dmemory32
wire[14:0] upg_adr_w; //链接dmemory32
wire[31:0] upg_dat_w; //链接dmemory32 and decoder
wire upg_done_w; //链接dmemory32
wire upg_tx=tx;
wire upg_rx=rx;
uart_bmpg_0 uart(.upg_clk_i(upg_clk_o),.upg_rst_i(upg_rst),.upg_rx_i(upg_rx),
.upg_clk_o(upg_clk_w),.upg_wen_o(upg_wen_w),.upg_adr_o(upg_adr_w),.upg_dat_o(upg_dat_w),
.upg_done_o(upg_done_w),.upg_tx_o(upg_tx));

//dmeory32的wires
wire cpu_clk=upg_clk;
wire ram_wen_w;//链接controller
wire[13:0] ram_adr_w;//链接ALU的alu_result
wire[31:0] ram_dat_i_w;//链接decoder的read_data_2
wire[31:0] ram_dat_o_w;//bind ifetc
dmemory32_0 mem(.ram_clk_i(cpu_clk),.ram_wen_i(ram_wen_w),.ram_adr_i(ram_adr_w),
.ram_dat_i(ram_dat_i_w),.ram_dat_o(ram_dat_o_w),.upg_rst_i(upg_rst),.upg_clk_i(upg_clk_w),
.upg_wen_i(upg_wen_w),.upg_adr_i(upg_adr_w),.upg_dat_i(upg_dat_w),.upg_done_i(upg_done_w));

wire [31:0] Instruction_w;//bind ifetc alu

//coltroler的wires
wire[5:0] Opcode_w = Instruction_w[31:26];
wire[5:0] Function_opcode_w=Instruction_w[5:0];
wire Jr_w; //bind ifetc and alu
wire Jmp_w; //bind decoder
wire Jal_w; //bind decoder
wire Branch_w; //bind decoder
wire nBranch_w; //bind decoder
wire RegDST_w; //bind decoder
wire MemtoReg_w; //bind decoder
wire RegWrite_w; //bind decoder
wire ALUSrc_w; //bind alu
wire I_format_w; //bind alu
wire Sftmd_w; // bind alu
wire[1:0] ALUOp_w;
control32 control(.Opcode(Opcode_w),.Function_opcode(Function_opcode_w),.Jr(Jr_w),.RegDST(RegDST_w),.ALUSrc(ALUSrc_w), 
.MemtoReg(MemtoReg_w), .RegWrite(RegWrite_w), .MemWrite(ram_wen_w),.Branch(Branch_w), .nBranch(nBranch_w), 
.Jmp(Jmp_w), .Jal(Jal_w), .I_format(I_format_w), .Sftmd(Sftmd_w), .ALUOp(ALUOp_w));


// from decoder 
wire[31:0] Read_data_1_w; //binde decoder and ifetc
wire[31:0] Imme_extend_w; //bind decoder
wire[4:0] Shamt_w=Instruction_w[10:6];
wire[31:0] PC_plus_4_w; //bind ifetc 
wire Zero_w; //bind ifetc
wire [31:0] Addr_result_w;//bind ifetc
Executs32 executs(.Read_data_1(Read_data_1_w), .Read_data_2(ram_dat_i_w), .Imme_extend(Imme_extend_w),
.Function_opcode(Function_opcode_w), .opcode(Opcode_w), .ALUOp(ALUOp_w),
.Shamt(Shamt_w), .ALUSrc(ALUSrc_w), .I_format(I_format_w), .Zero(Zero_w), .Sftmd(Sftmd_w),
.ALU_Result(ram_adr_w), .Addr_Result(Addr_result_w), .PC_plus_4(PC_plus_4_w), .Jr(Jr_w));


wire [31:0] opcplus4_w;//bind ifetc
Idecode32 decode(
.Instruction(Instruction_w), .read_data(upg_dat_w), .ALU_result(ram_adr_w), .Jal(Jal_w),
.RegWrite(RegWrite_w), .MemtoReg(MemtoReg_w), .RegDst(RegDST_w), .clock(cpu_clk), .reset(rst), .opcplus4(opcplus4_w),
.read_data_1(Read_data_1_w), .read_data_2(ram_dat_i_w), .imme_extend(Imme_extend_w));

wire[31:0] pco_w;
Ifetc32 ifetc(.Instruction_out(Instruction_w),.branch_base_addr(PC_plus_4_w),.Addr_result(Addr_result_w),
            .Read_data_1(Read_data_1_w),.Branch(Branch_w),.nBranch(nBranch_w),.Jmp(Jmp_w),.Jal(Jal_w),.Jr(Jr_w),.Zero(Zero_w),
            .clock(cpu_clk),.reset(rst),.link_addr(opcplus4_w),.pco(pco_w), .Instruction(ram_dat_o_w));

endmodule
