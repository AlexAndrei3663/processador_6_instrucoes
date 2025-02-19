
typedef enum logic [3:0] {INICIO = 4'b0000,
                          BUSCA,
                          DECOD,
                          CARREGAR,
                          ARMAZENAR,
                          SOMAR,
                          CARREGAR_CONST,
                          SUBTRAIR,
                          SALTAR_ZERO,
                          SALTAR} statetype;

typedef enum logic [3:0] {MOVR  = 4'b0000,
                          MOVD  = 4'b0001,
                          ADD   = 4'b0010,
                          MOVC  = 4'b0011,
                          SUB   = 4'b0100,
                          JMPZ  = 4'b0101} opcode;

module unidade_controle(input  logic        clk, reset, 
                        output logic [15:0] I_addr,
                        output logic        I_rd,
                        input  logic [15:0] I_data,
                        output logic [7:0]  D_addr,
                        output logic        D_rd, D_wr,
                        output logic [7:0]  RF_W_data,
                        output logic        RF_s0, RF_s1,
                        output logic [3:0]  RF_W_addr, RF_Rp_addr, RF_Rq_addr,
                        output logic        RF_W_wr, RF_Rp_rd, RF_Rq_rd,
                        input  logic        RF_Rp_zero,
                        output logic        alu_s0, alu_s1);

    logic PC_ld, PC_clr, PC_inc, IR_ld;
    logic [15:0] d_PC, d_IR, IR_data;

  assign d_IR = {{8{IR_data[7]}}, IR_data[7:0]};
    assign I_addr = d_PC;

    PC PC_dev(clk, d_PC, d_IR, d_PC, PC_ld, PC_clr, PC_inc);
    IR IR_dev(clk, reset, IR_ld, I_data, IR_data);
    bloco_controle controle_dev(clk, reset,
                                PC_ld, PC_clr, PC_inc, I_rd, IR_ld, 
                                IR_data, 
                                D_addr, 
                                D_rd, D_wr,
                                RF_W_data,
                                RF_s0, RF_s1,
                                RF_W_addr, RF_Rp_addr, RF_Rq_addr,
                                RF_W_wr, RF_Rp_rd, RF_Rq_rd,
                                RF_Rp_zero,
                                alu_s0, alu_s1);
endmodule

module PC(input  logic        clk,
          input  logic [15:0] d_PC, d_IR,
          output logic [15:0] q,
          input  logic        ld, clr, up);

    always_ff @(posedge clk)
        if (clr) q <= 16'b0;
        else if (up) q <= d_PC + 1;
        else if (ld) q <= d_PC + d_IR - 1;

endmodule

module IR(input   logic        clk, reset, ld,
          input   logic [15:0] d,
          output  logic [15:0] q);

    always_ff @(posedge clk, posedge reset)
        if      (reset) q <= 16'b0;
        else if (ld)    q <= d;
         
endmodule

module bloco_controle(input  logic        clk, reset,
                      output logic        PC_ld, PC_clr, PC_inc, I_rd, IR_ld,
                      input  logic [15:0] IR_data,
                      output logic [7:0]  D_addr,
                      output logic        D_rd, D_wr,
                      output logic [7:0]  RF_W_data,
                      output logic        RF_s0, RF_s1,
                      output logic [3:0]  RF_W_addr, RF_Rp_addr, RF_Rq_addr,
                      output logic        RF_W_wr, RF_Rp_rd, RF_Rq_rd,
                      input  logic        RF_Rp_zero,
                      output logic        alu_s0, alu_s1);

    statetype state, nextstate; 
    logic [1:0] alu;
    logic [1:0] rf;
    opcode op;
    logic [3:0] Ra, Rb, Rc;
    logic [7:0] d, C;
    
    assign {alu_s1, alu_s0} = alu;
    assign {RF_s1, RF_s0}   = rf;
    assign op               = IR_data[15:12];
    assign Ra               = IR_data[11:8];
    assign Rb               = IR_data[7:4];
    assign Rc               = IR_data[3:0];
    assign d                = IR_data[7:0];
    assign RF_W_data        = IR_data[7:0];

    always_ff @(posedge clk, posedge reset)
        if (reset) state <= INICIO;
        else       state <= nextstate;

    always_comb
        begin

            PC_ld = 0; PC_clr = 0; PC_inc = 0; I_rd = 0; IR_ld = 0;
            D_addr = 8'b00000000;
            D_rd = 0; D_wr = 0;
            rf = 2'b00;
            RF_W_addr = 4'b0000; RF_Rp_addr = 4'b0000; RF_Rq_addr = 4'b0000;
            RF_W_wr = 0; RF_Rp_rd = 0; RF_Rq_rd = 0;
            alu = 2'b00;

            case (state)
                INICIO:
                    begin
                        PC_clr = 1;
                    end
                BUSCA:
                    begin
                        I_rd   = 1;
                        PC_inc = 1;
                        IR_ld  = 1;
                    end
                DECOD:
                    begin
                        // no change    
                    end
                CARREGAR:
                    begin
                        D_addr    = d;
                        D_rd      = 1;
                        rf        = 2'b01;
                        RF_W_addr = Ra;
                        RF_W_wr   = 1;
                    end
                ARMAZENAR:
                    begin
                        D_addr    = d;
                        D_wr      = 1;
                        RF_Rp_addr = Ra;
                        RF_Rp_rd   = 1;
                    end
                SOMAR:
                    begin
                        RF_Rp_addr = Rb;
                        RF_Rp_rd   = 1;
                        rf         = 2'b00;
                        RF_Rq_addr = Rc;
                        RF_Rq_rd   = 1;
                        RF_W_addr  = Ra;
                        RF_W_wr    = 1;
                        alu        = 2'b01;
                    end
                CARREGAR_CONST:
                    begin
                        rf        = 2'b10;
                        RF_W_addr = Ra;
                        RF_W_wr   = 1;
                    end
                SUBTRAIR:
                    begin
                        RF_Rp_addr = Rb;
                        RF_Rp_rd   = 1;
                        rf         = 2'b00;
                        RF_Rq_addr = Rc;
                        RF_Rq_rd   = 1;
                        RF_W_addr  = Ra;
                        RF_W_wr    = 1;
                        alu        = 2'b10;
                    end
                SALTAR_ZERO:
                    begin
                        RF_Rp_addr = Ra;
                        RF_Rp_rd   = 1;
                    end
                SALTAR:
                    begin
                        PC_ld = 1;
                    end
                default:
                    begin
                        PC_ld = 0; PC_clr = 0; PC_inc = 0; I_rd = 0; IR_ld = 0;
                        D_addr = 8'b00000000;
                        D_rd = 0; D_wr = 0;
                        rf = 2'b00;
                        RF_W_addr = 4'b0000; RF_Rp_addr = 4'b0000; RF_Rq_addr = 4'b0000;
                        RF_W_wr = 0; RF_Rp_rd = 0; RF_Rq_rd = 0;
                        alu = 2'b00;
                    end

            endcase
        end

    always_comb
        begin
            case (state)
                INICIO:
                    nextstate = BUSCA;
                BUSCA:
                    nextstate = DECOD;
                DECOD:
                    case(op)
                        MOVR:       nextstate = CARREGAR;                           
                        MOVD:       nextstate = ARMAZENAR;
                        ADD :       nextstate = SOMAR;
                        MOVC:       nextstate = CARREGAR_CONST;
                        SUB :       nextstate = SUBTRAIR;
                        JMPZ:       nextstate = SALTAR_ZERO;
                        default:    nextstate = INICIO;
                    endcase
                CARREGAR:       nextstate = BUSCA;
                ARMAZENAR:      nextstate = BUSCA;
                SOMAR:          nextstate = BUSCA;
                CARREGAR_CONST: nextstate = BUSCA;
                SUBTRAIR:       nextstate = BUSCA;
                SALTAR_ZERO:
                    if(RF_Rp_zero)  nextstate = SALTAR;
                    else            nextstate = BUSCA;  
                SALTAR:         nextstate = BUSCA;
                default:        nextstate = BUSCA;  // should never happen
            endcase
        end
endmodule
