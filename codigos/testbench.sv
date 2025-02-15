// testbench
module testbench();

    logic        clk, rst;
    logic        i_rd, d_rd, d_wr;
    logic [15:0] i_data, r_data, i_addr, d_addr, w_data;

    // Instanciação do bloco de processamento
    mips dut(clk, rst, i_data, r_data, i_rd, d_rd, d_wr, i_addr, d_addr, w_data);

    // Instanciação da memória de programa
    program_memory pm(i_addr, i_rd, i_data);

    // Instanciação da memória de dados
    data_memory dm(clk, w_data, d_addr, d_wr, d_rd, r_data);

    // Inicia os testes
    initial
        begin
        reset <= 1; # 22; reset <= 0;
        end

    // Geração do sinal de clock
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
