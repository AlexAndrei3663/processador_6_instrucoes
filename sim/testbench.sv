// testbench
module testbench();

    logic        clk, rst;
    logic        i_rd, d_rd, d_wr;
    logic [7:0]  d_addr;
    logic [15:0] i_data, r_data, i_addr, w_data;

    // Instanciacao do bloco de processamento
    mips dut(clk, rst, i_data, r_data, i_rd, d_rd, d_wr, d_addr, i_addr, w_data);

    // Instanciacao da memória de programa
    program_memory pm(i_addr, i_rd, i_data);

    // Instanciacao da memória de dados
    data_memory dm(clk, w_data, d_addr, d_wr, d_rd, r_data);

    // Inicia os testes
    initial
        begin
        rst <= 1; # 22; rst <= 0;
        end

    // Geracao do sinal de clock
    always
        begin
        clk <= 1; # 5; clk <= 0; # 5;
        end

    always@(negedge clk)
        begin
            if(d_wr & d_addr == 8'd255) begin
                assert(w_data == 8'h0D)
                    $display("Fibonacci completely successful");
                else $error("Simulation failed");
                $finish;
            end
        end
endmodule
