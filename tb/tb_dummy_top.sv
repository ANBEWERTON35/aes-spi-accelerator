`timescale 1ns/1ps

module tb_dummy_top;

    logic       clk;
    logic       rst_n;
    logic [7:0] count;

    // Instância do DUT localizado na pasta rtl/
    dummy_top dut (
        .clk   (clk),
        .rst_n (rst_n),
        .count (count)
    );

    // Geração do clock (100MHz)
    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;

        #20;
        rst_n = 1;

        #100;

        $display("[SUCESSO] Simulação executada com sucesso! Contador: %d", count);
        $finish;
    end

endmodule