`timescale 1ns/1ps

module tb_semana_03;

    // Sinais da S-Box e InvS-Box
    logic [7:0]   sbox_in, sbox_out, inv_sbox_out;

    // Sinais das transformações diretas
    logic [127:0] subbytes_in, subbytes_out;
    logic [127:0] shiftrows_in, shiftrows_out;
    logic [127:0] mixcols_in, mixcols_out;
    logic [127:0] ark_in, ark_key, ark_out;

    // Sinais das transformações inversas
    logic [127:0] inv_subbytes_in, inv_subbytes_out;
    logic [127:0] inv_shiftrows_in, inv_shiftrows_out;
    logic [127:0] inv_mixcols_in, inv_mixcols_out;

    int erros = 0;

    // Instâncias S-Box e InvS-Box
    minisoc_aes_sbox u_sbox (
        .in_byte  (sbox_in),
        .out_byte (sbox_out)
    );

    minisoc_aes_inv_sbox u_inv_sbox (
        .in_byte  (sbox_out),
        .out_byte (inv_sbox_out)
    );

    // Instâncias das transformações diretas
    minisoc_aes_sub_bytes u_sub_bytes (
        .state_in  (subbytes_in),
        .state_out (subbytes_out)
    );

    minisoc_aes_shift_rows u_shift_rows (
        .state_in  (shiftrows_in),
        .state_out (shiftrows_out)
    );

    minisoc_aes_mix_columns u_mix_columns (
        .state_in  (mixcols_in),
        .state_out (mixcols_out)
    );

    minisoc_aes_add_round_key u_add_round_key (
        .state_in  (ark_in),
        .round_key (ark_key),
        .state_out (ark_out)
    );

    // Instâncias das transformações inversas
    minisoc_aes_inv_sub_bytes u_inv_sub_bytes (
        .state_in  (inv_subbytes_in),
        .state_out (inv_subbytes_out)
    );

    minisoc_aes_inv_shift_rows u_inv_shift_rows (
        .state_in  (inv_shiftrows_in),
        .state_out (inv_shiftrows_out)
    );

    minisoc_aes_inv_mix_columns u_inv_mix_columns (
        .state_in  (inv_mixcols_in),
        .state_out (inv_mixcols_out)
    );

    // =========================================================================
    // Vetores FIPS-197 (Apêndice B — Cifragem)
    // =========================================================================
    localparam logic [127:0] B_PLAINTEXT    = 128'h3243f6a8885a308d313198a2e0370734;
    localparam logic [127:0] B_RK0          = 128'h2b7e151628aed2a6abf7158809cf4f3c;

    localparam logic [127:0] B_R1_START     = 128'h193de3bea0f4e22b9ac68d2ae9f84808;
    localparam logic [127:0] B_R1_SUBBYTES  = 128'hd42711aee0bf98f1b8b45de51e415230;
    localparam logic [127:0] B_R1_SHIFTROWS = 128'hd4bf5d30e0b452aeb84111f11e2798e5;
    localparam logic [127:0] B_R1_MIXCOLS   = 128'h046681e5e0cb199a48f8d37a2806264c;
    localparam logic [127:0] B_RK1          = 128'ha0fafe1788542cb123a339392a6c7605;
    localparam logic [127:0] B_R2_START     = 128'ha49c7ff2689f352b6b5bea43026a5049;

    localparam logic [127:0] B_R10_START    = 128'heb40f21e592e38848ba113e71bc342d2;
    localparam logic [127:0] B_R10_SUBBYTES = 128'he9098972cb31075f3d327d94af2e2cb5;
    localparam logic [127:0] B_R10_SHIFTROWS= 128'he9317db5cb322c723d2e895faf090794;
    localparam logic [127:0] B_RK10         = 128'hd014f9a8c9ee2589e13f0cc8b6630ca6;
    localparam logic [127:0] B_CIPHERTEXT   = 128'h3925841d02dc09fbdc118597196a0b32;

    // =========================================================================
    // Vetores FIPS-197 (Apêndice C.1 — Cifragem Inversa)
    // =========================================================================
    localparam logic [127:0] C_CIPHERTEXT       = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
    localparam logic [127:0] C_RK10             = 128'h13111d7fe3944a17f307a78b4d2b30c5;

    localparam logic [127:0] C_IR9_START        = 128'h7ad5fda789ef4e272bca100b3d9ff59f;
    localparam logic [127:0] C_IR9_INVSHIFTROWS = 128'h7a9f102789d5f50b2beffd9f3dca4ea7;
    localparam logic [127:0] C_IR9_INVSUBBYTES  = 128'hbd6e7c3df2b5779e0b61216e8b10b689;
    localparam logic [127:0] C_RK9              = 128'h549932d1f08557681093ed9cbe2c974e;
    localparam logic [127:0] C_IR9_ADDROUNDKEY  = 128'he9f74eec023020f61bf2ccf2353c21c7;
    localparam logic [127:0] C_IR9_INVMIXCOLS   = 128'h54d990a16ba09ab596bbf40ea111702f;

    localparam logic [127:0] C_IR0_START        = 128'h6353e08c0960e104cd70b751bacad0e7;
    localparam logic [127:0] C_IR0_INVSHIFTROWS = 128'h63cab7040953d051cd60e0e7ba70e18c;
    localparam logic [127:0] C_IR0_INVSUBBYTES  = 128'h00102030405060708090a0b0c0d0e0f0;
    localparam logic [127:0] C_RK0              = 128'h000102030405060708090a0b0c0d0e0f;
    localparam logic [127:0] C_PLAINTEXT        = 128'h00112233445566778899aabbccddeeff;

    // Modelo de referência da InvS-Box em GF(2^8)
    function automatic logic [7:0] gf_mul(input logic [7:0] a, input logic [7:0] b);
        logic [7:0] p  = 8'h00;
        logic [7:0] aa = a;
        logic [7:0] bb = b;
        for (int i = 0; i < 8; i++) begin
            if (bb[0]) p ^= aa;
            aa = (aa[7]) ? ((aa << 1) ^ 8'h1b) : (aa << 1);
            bb >>= 1;
        end
        return p;
    endfunction

    function automatic logic [7:0] ref_inv_sbox(input logic [7:0] z);
        logic [7:0] y;
        logic [7:0] inv;
        logic [7:0] base;
        int exp;
        for (int i = 0; i < 8; i++) begin
            y[i] = z[(i+2)%8] ^ z[(i+5)%8] ^ z[(i+7)%8] ^ 1'(8'h05 >> i);
        end
        inv  = (y == 8'h00) ? 8'h00 : 8'h01;
        base = y;
        exp  = 254;
        while (exp > 0) begin
            if (exp[0]) inv = gf_mul(inv, base);
            base = gf_mul(base, base);
            exp >>= 1;
        end
        return inv;
    endfunction

    initial begin
        $display("Iniciando testes unitarios da Semana 3...");

        // (a) Varredura das 256 entradas: InvS-Box(S-Box(x)) == x e modelo GF(2^8)
        for (int i = 0; i < 256; i++) begin
            sbox_in = i[7:0];
            #1;
            if (inv_sbox_out !== i[7:0] || inv_sbox_out !== ref_inv_sbox(sbox_out)) begin
                $error("Falha InvS-Box[0x%02h]: esperado 0x%02h, obtido 0x%02h", sbox_out, i[7:0], inv_sbox_out);
                erros++;
            end
        end
        if (erros == 0) $display("PASS: InvS-Box (256/256 entradas)");

        // (b) FIPS-197 Apêndice B — Cifragem (AddRoundKey + MixColumns + rodada completa)
        ark_in  = B_PLAINTEXT;
        ark_key = B_RK0;
        #1;
        if (ark_out !== B_R1_START) begin
            $error("Falha AddRoundKey R0: esperado %h, obtido %h", B_R1_START, ark_out);
            erros++;
        end else $display("PASS: AddRoundKey (Apendice B - Rodada 0)");

        subbytes_in = ark_out;
        #1;
        shiftrows_in = subbytes_out;
        #1;
        mixcols_in = shiftrows_out;
        #1;
        if (mixcols_out !== B_R1_MIXCOLS) begin
            $error("Falha MixColumns R1: esperado %h, obtido %h", B_R1_MIXCOLS, mixcols_out);
            erros++;
        end else $display("PASS: MixColumns (Apendice B - Rodada 1)");

        ark_in  = mixcols_out;
        ark_key = B_RK1;
        #1;
        if (ark_out !== B_R2_START) begin
            $error("Falha AddRoundKey R1: esperado %h, obtido %h", B_R2_START, ark_out);
            erros++;
        end else $display("PASS: AddRoundKey (Apendice B - Rodada 1)");

        // Rodada 10 (sem MixColumns)
        subbytes_in = B_R10_START;
        #1;
        shiftrows_in = subbytes_out;
        #1;
        ark_in  = shiftrows_out;
        ark_key = B_RK10;
        #1;
        if (ark_out !== B_CIPHERTEXT) begin
            $error("Falha Ciphertext R10: esperado %h, obtido %h", B_CIPHERTEXT, ark_out);
            erros++;
        end else $display("PASS: Rodada Final R10 (Apendice B - Ciphertext)");

        // (c) FIPS-197 Apêndice C.1 — Cifragem Inversa
        ark_in  = C_CIPHERTEXT;
        ark_key = C_RK10;
        #1;
        if (ark_out !== C_IR9_START) begin
            $error("Falha Init AddRoundKey C.1: esperado %h, obtido %h", C_IR9_START, ark_out);
            erros++;
        end else $display("PASS: AddRoundKey Inicial (Apendice C.1 - RK10)");

        // Rodada 1 Inversa: InvShiftRows -> InvSubBytes -> AddRoundKey(RK9) -> InvMixColumns
        inv_shiftrows_in = ark_out;
        #1;
        if (inv_shiftrows_out !== C_IR9_INVSHIFTROWS) begin
            $error("Falha InvShiftRows C.1 R1: esperado %h, obtido %h", C_IR9_INVSHIFTROWS, inv_shiftrows_out);
            erros++;
        end

        inv_subbytes_in = inv_shiftrows_out;
        #1;
        if (inv_subbytes_out !== C_IR9_INVSUBBYTES) begin
            $error("Falha InvSubBytes C.1 R1: esperado %h, obtido %h", C_IR9_INVSUBBYTES, inv_subbytes_out);
            erros++;
        end

        ark_in  = inv_subbytes_out;
        ark_key = C_RK9;
        #1;
        if (ark_out !== C_IR9_ADDROUNDKEY) begin
            $error("Falha AddRoundKey C.1 R1: esperado %h, obtido %h", C_IR9_ADDROUNDKEY, ark_out);
            erros++;
        end

        inv_mixcols_in = ark_out;
        #1;
        if (inv_mixcols_out !== C_IR9_INVMIXCOLS) begin
            $error("Falha InvMixColumns C.1 R1: esperado %h, obtido %h", C_IR9_INVMIXCOLS, inv_mixcols_out);
            erros++;
        end else $display("PASS: Rodada 1 Inversa Completa (Apendice C.1)");

        // Rodada Final Inversa (sem InvMixColumns): InvShiftRows -> InvSubBytes -> AddRoundKey(RK0)
        inv_shiftrows_in = C_IR0_START;
        #1;
        if (inv_shiftrows_out !== C_IR0_INVSHIFTROWS) begin
            $error("Falha InvShiftRows Final C.1: esperado %h, obtido %h", C_IR0_INVSHIFTROWS, inv_shiftrows_out);
            erros++;
        end

        inv_subbytes_in = inv_shiftrows_out;
        #1;
        if (inv_subbytes_out !== C_IR0_INVSUBBYTES) begin
            $error("Falha InvSubBytes Final C.1: esperado %h, obtido %h", C_IR0_INVSUBBYTES, inv_subbytes_out);
            erros++;
        end

        ark_in  = inv_subbytes_out;
        ark_key = C_RK0;
        #1;
        if (ark_out !== C_PLAINTEXT) begin
            $error("Falha Plaintext Final C.1: esperado %h, obtido %h", C_PLAINTEXT, ark_out);
            erros++;
        end else $display("PASS: Rodada Final Inversa (Apendice C.1 - Plaintext Recuperado)");

        // Resultado final
        if (erros == 0) begin
            $display("==================================================");
            $display("TODOS OS TESTES DA SEMANA 3 PASSARAM! (PASS)");
            $display("==================================================");
        end else begin
            $fatal(1, "FALHA: %0d erro(s) encontrado(s) na simulacao.", erros);
        end

        $finish;
    end

endmodule