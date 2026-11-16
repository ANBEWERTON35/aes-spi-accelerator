`timescale 1ns/1ps

module tb_semana_02;

    logic [7:0]   sbox_in, sbox_out;
    logic [127:0] subbytes_in, subbytes_out;
    logic [127:0] shiftrows_in, shiftrows_out;
    int           erros = 0;

    minisoc_aes_sbox u_sbox (
        .in_byte  (sbox_in),
        .out_byte (sbox_out)
    );

    minisoc_aes_sub_bytes u_sub_bytes (
        .state_in  (subbytes_in),
        .state_out (subbytes_out)
    );

    minisoc_aes_shift_rows u_shift_rows (
        .state_in  (shiftrows_in),
        .state_out (shiftrows_out)
    );

    // Vetores FIPS-197 (Apêndice B) - Rodada 1
    localparam logic [127:0] R1_START     = 128'h193de3bea0f4e22b9ac68d2ae9f84808;
    localparam logic [127:0] R1_SUBBYTES  = 128'hd42711aee0bf98f1b8b45de51e415230;
    localparam logic [127:0] R1_SHIFTROWS = 128'hd4bf5d30e0b452aeb84111f11e2798e5;

    // Vetores FIPS-197 (Apêndice B) - Rodada 10
    localparam logic [127:0] R10_START     = 128'heb40f21e592e38848ba113e71bc342d2;
    localparam logic [127:0] R10_SUBBYTES  = 128'he9098972cb31075f3d327d94af2e2cb5;
    localparam logic [127:0] R10_SHIFTROWS = 128'he9317db5cb322c723d2e895faf090794;

    // Modelo de referência da S-Box em GF(2^8)
    function automatic logic [7:0] gf_mul(input logic [7:0] a, input logic [7:0] b);
        logic [7:0] p = 8'h00;
        logic [7:0] aa = a;
        logic [7:0] bb = b;
        for (int i = 0; i < 8; i++) begin
            if (bb[0]) p ^= aa;
            aa = (aa[7]) ? ((aa << 1) ^ 8'h1b) : (aa << 1);
            bb >>= 1;
        end
        return p;
    endfunction

    function automatic logic [7:0] ref_sbox(input logic [7:0] x);
        logic [7:0] inv = (x == 8'h00) ? 8'h00 : 8'h01;
        logic [7:0] base = x;
        logic [7:0] aff;
        int exp = 254;
        while (exp > 0) begin
            if (exp[0]) inv = gf_mul(inv, base);
            base = gf_mul(base, base);
            exp >>= 1;
        end
        for (int i = 0; i < 8; i++) begin
            aff[i] = inv[i] ^ inv[(i+4)%8] ^ inv[(i+5)%8] ^ inv[(i+6)%8] ^ inv[(i+7)%8] ^ (8'h63 >> i);
        end
        return aff;
    endfunction

    initial begin
        $display("Iniciando testes completos da Semana 2...");

        // (a) Varredura das 256 entradas da S-Box
        for (int i = 0; i < 256; i++) begin
            sbox_in = i[7:0];
            #1;
            if (sbox_out !== ref_sbox(i[7:0])) begin
                $error("Falha S-Box[0x%02h]: esperado 0x%02h, obtido 0x%02h", i[7:0], ref_sbox(i[7:0]), sbox_out);
                erros++;
            end
        end
        if (erros == 0) $display("PASS: S-Box (256/256 entradas)");

        // (b) Rodada 1 - FIPS-197 Apêndice B
        subbytes_in = R1_START;
        #1;
        if (subbytes_out !== R1_SUBBYTES) begin
            $error("Falha SubBytes R1: esperado %h, obtido %h", R1_SUBBYTES, subbytes_out);
            erros++;
        end else $display("PASS: SubBytes (Rodada 1)");

        shiftrows_in = subbytes_out;
        #1;
        if (shiftrows_out !== R1_SHIFTROWS) begin
            $error("Falha ShiftRows R1: esperado %h, obtido %h", R1_SHIFTROWS, shiftrows_out);
            erros++;
        end else $display("PASS: ShiftRows (Rodada 1)");

        // (c) Rodada 10 - FIPS-197 Apêndice B
        subbytes_in = R10_START;
        #1;
        if (subbytes_out !== R10_SUBBYTES) begin
            $error("Falha SubBytes R10: esperado %h, obtido %h", R10_SUBBYTES, subbytes_out);
            erros++;
        end else $display("PASS: SubBytes (Rodada 10)");

        shiftrows_in = subbytes_out;
        #1;
        if (shiftrows_out !== R10_SHIFTROWS) begin
            $error("Falha ShiftRows R10: esperado %h, obtido %h", R10_SHIFTROWS, shiftrows_out);
            erros++;
        end else $display("PASS: ShiftRows (Rodada 10)");

        if (erros == 0)
            $display("RESULTADO FINAL: TODOS OS TESTES PASSARAM.");
        else
            $fatal(1, "RESULTADO FINAL: %0d erro(s) encontrado(s).", erros);

        $finish;
    end
endmodule