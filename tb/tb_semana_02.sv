`timescale 1ns/1ps

module tb_semana_02;

    // Sinais
    logic [7:0]   sbox_in, sbox_out;
    logic [127:0] subbytes_in, subbytes_out;
    logic [127:0] shiftrows_in, shiftrows_out;
    
    // Instanciações
    minisoc_aes_sbox u_sbox (
        .in_byte(sbox_in), .out_byte(sbox_out)
    );
    
    minisoc_aes_sub_bytes u_sub_bytes (
        .state_in(subbytes_in), .state_out(subbytes_out)
    );
    
    minisoc_aes_shift_rows u_shift_rows (
        .state_in(shiftrows_in), .state_out(shiftrows_out)
    );

    // Vetores de referência (FIPS-197, Apêndice B, Rodada 1)
    localparam logic [127:0] START_OF_ROUND = 128'h193de3bea0f4e22b9ac68d2ae9f84808;
    localparam logic [127:0] AFTER_SUBBYTES = 128'hd42711aee0bf98f1b8b45de51e415230;
    localparam logic [127:0] AFTER_SHIFTROWS = 128'hd4bf5d30e0b452aeb84111f11e2798e5;

    initial begin
        $display("Iniciando testes da Semana 2...");

        // Teste (a): S-Box nas 256 entradas (Exemplo simplificado para h00 e h53)
        sbox_in = 8'h00;
        #1;
        if (sbox_out !== 8'h63) $error("Falha na S-Box para 00. Esperado 63, Obtido %h", sbox_out);
        
        sbox_in = 8'h53;
        #1;
        if (sbox_out !== 8'hed) $error("Falha na S-Box para 53. Esperado ed, Obtido %h", sbox_out);

        // Teste (b): SubBytes
        subbytes_in = START_OF_ROUND;
        #1;
        if (subbytes_out !== AFTER_SUBBYTES) 
            $error("Falha em SubBytes. Esperado %h, Obtido %h", AFTER_SUBBYTES, subbytes_out);
        else 
            $display("PASS: SubBytes");

        // Teste (c): ShiftRows
        shiftrows_in = subbytes_out; // Aplica no resultado do SubBytes
        #1;
        if (shiftrows_out !== AFTER_SHIFTROWS) 
            $error("Falha em ShiftRows. Esperado %h, Obtido %h", AFTER_SHIFTROWS, shiftrows_out);
        else 
            $display("PASS: ShiftRows");

        $display("Testes concluídos.");
        $finish;
    end
endmodule