// Bloco para a memória de programa
module program_memory(input   logic [15:0] addr,
                      input   logic        rd,
                      output  logic [15:0] data);

    logic [15:0] mem[15:0];

    initial $readmemh("memfile.dat", mem);
    
    assign data = rd ? mem[addr] : '0;
endmodule

// Bloco do processador
module mips(input logic clk, rst,
            input logic [15:0] i_data, r_data,
            output logic i_rd, d_rd, d_wr
            output logic [15:0] i_addr, d_addr, w_data);

    logic [7:0] rf_w_data;
    logic [1:0] rf_s;
    logic [3:0] rf_w_addr, rf_rp_addr, rf_rq_addr;
    logic rf_w_wr, rf_rp_rd, rf_rq_rd;
    logic rf_rp_zero,
    logic [1:0] alu_s;

    unidade_controle uc(clk, rst, 
                        i_addr,
                        i_rd,
                        i_data,
                        d_addr,
                        d_rd, d_wr,
                        rf_w_data,
                        rf_s[0], rf_s[1],
                        rf_w_addr, rf_rp_addr, rf_rq_addr,
                        rf_w_wr, rf_rp_rd, rf_rq_rd,
                        rf_rp_zero
                        alu_s[0], alu_s[1]);

    operational_block opb(clk, 
                      r_data, 
                      rf_w_data, 
                      rf_w_addr, rf_rp_addr, rf_rq_addr
                      rf_w_wr, rf_rp_rd, rf_rq_rd,
                      rf_s, alu_s,
                      w_data,
                      rf_rp_zero);

endmodule