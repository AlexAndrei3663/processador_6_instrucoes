// Mux2
module mux2 #(parameter WIDTH = 16)
             (input  logic [WIDTH-1:0] d0, d1,
              input  logic             s, 
              output logic [WIDTH-1:0] y);

  assign y = s ? d1 : d0;
endmodule

// Mux para seleção do W_data
module mux3 #(parameter WIDTH = 16)
             (input  logic [WIDTH-1:0] d0, d1, d2,
              input  logic [1:0]       s, 
              output logic [WIDTH-1:0] y);

  typedef enum logic [1:0] {
    ALU   = 2'b00,
    DREG  = 2'b01,
    WDATA = 2'b10
  } mux_options;

  always_comb 
    casez (s)
      ALU:   y = d0;
      DREG:  y = d1;
      WDATA: y = d2;
    endcase
endmodule

// Banco de registradores - RF
module register_bank #(parameter WIDTH = 16, REGBITS = 4)
                (input  logic               clk, 
                 input  logic [WIDTH-1:0]   w_data, 
                 input  logic [REGBITS-1:0] w_addr, rp_addr, rq_addr, 
                 input  logic               w_wr, rp_rd, rq_rd, 
                 output logic [WIDTH-1:0]   rp_data, rq_data);

   logic [WIDTH-1:0] ram [2**REGBITS-1:0];

  always @(posedge clk)
    if (w_wr) ram[w_addr] <= w_data;

  assign rp_data = rp_rd ? ram[rp_addr] : '0;
  assign rq_data = rq_rd ? ram[rq_addr] : '0;
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

// Detector de zero
module zero_detect #(parameter WIDTH = 16)
                   (input  logic [WIDTH-1:0] a, 
                    output logic             y);

   assign y = ( a == 0 );
endmodule	

// Inversor
module inv #(parameter WIDTH = 16)
            (input  logic [WIDTH-1:0] a,
             output logic [WIDTH-1:0] y);

  assign y = ~a;
endmodule

// Mux inverter para as operações de subtração
module condinv #(parameter WIDTH = 16)
                (input  logic [WIDTH-1:0] a,
                 input  logic             s,
                 output logic [WIDTH-1:0] y);

  logic [WIDTH-1:0] neg_a;

  inv  #(WIDTH) inverter(a, neg_a);
  mux2 #(WIDTH) mux_inv(a, neg_a, s, y);
endmodule

// Somador para as operações de adição e subtração
module adder #(parameter WIDTH = 16)
              (input  logic [WIDTH-1:0] a, b,
               input  logic             cin,
               output logic [WIDTH-1:0] y);

  assign y = a + b + cin;
endmodule

// Unidade Logica Aritmética
module alu #(parameter WIDTH = 16)
             (input  logic [WIDTH-1:0] a, b,
              input  logic [1:0]       s, 
              output logic [WIDTH-1:0] y);

  typedef enum logic [1:0] {
    BYPASS = 2'b00,
    ADD    = 2'b01,
    SUB    = 2'b10
  } alu_operations;

  logic [WIDTH-1:0] sum_result, inv_cond, inv_result;

  condinv #(WIDTH) cond_inv(b, s[1], inv_cond);
  adder   #(WIDTH) adder_mod(a, inv_cond, s[1], sum_result);

  always_comb
    case (s)
      BYPASS:  y = a;
      ADD:     y = sum_result;
      SUB:     y = sum_result;
      default: y = a;
    endcase
endmodule

// Bloco Operacional
module operational_block #(parameter WIDTH = 16, REGBITS = 4) 
                (input  logic               clk,
                 input  logic [WIDTH-1:0]   r_data,
                 input  logic [7:0]         rf_w_data,
                 input  logic [REGBITS-1:0] rf_w_addr, rf_rp_addr, rf_rq_addr,
                 input  logic               rf_w_wr, rf_rp_rd, rf_rq_rd,
                 input  logic [1:0]         rf_s, alu_s,
                 output logic [WIDTH-1:0]   w_data,
                 output logic               rf_rp_zero);

    logic [15:0] rp_data, rq_data, alu_result, mux3_result;

    mux3          #(WIDTH)          mux3_select(alu_result, r_data, {'0, rf_w_data}, rf_s, mux3_result);
    register_bank #(WIDTH, REGBITS) rf(clk, 
                                       mux3_result, 
                                       rf_w_addr, 
                                       rf_rp_addr, 
                                       rf_rq_addr, 
                                       rf_w_wr, 
                                       rf_rp_rd, 
                                       rf_rq_rd, 
                                       rp_data, 
                                       rq_data);
    alu           #(WIDTH)          alu_control(rp_data, rq_data, alu_s, alu_result);
    zero_detect   #(WIDTH)          zero_detect(rp_data, rf_rp_zero);
endmodule
