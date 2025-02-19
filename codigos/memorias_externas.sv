// Bloco para a memória de programa
module program_memory(input   logic [15:0] addr,
                      input   logic        rd,
                      output  logic [15:0] data);

    logic [15:0] mem[15:0];

    initial $readmemh("memfile.dat", mem);
    
    assign data = rd ? mem[addr] : '0;
endmodule

// Memoria de dados - D
module data_memory #(parameter WIDTH = 16, REGBITS = 8)
                (input  logic               clk, 
                 input  logic [WIDTH-1:0]   w_data, 
                 input  logic [REGBITS-1:0] addr, 
                 input  logic               wr, rd, 
                 output logic [WIDTH-1:0]   r_data);

   logic [WIDTH-1:0] mem [2**REGBITS-1:0];

  always @(posedge clk)
    if (wr) mem[addr] <= w_data;

  assign r_data = rd ? mem[addr] : '0;
endmodule
