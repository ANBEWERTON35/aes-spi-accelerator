module minisoc_aes_inv_shift_rows (
    input  logic [127:0] state_in,
    output logic [127:0] state_out
);

    logic [7:0] s_in  [0:15];
    logic [7:0] s_out [0:15];

    always_comb begin
        for (int i = 0; i < 16; i++) begin
            s_in[i] = state_in[127 - 8*i -: 8];
        end

        // Linha 0: sem deslocamento
        s_out[0]  = s_in[0];
        s_out[4]  = s_in[4];
        s_out[8]  = s_in[8];
        s_out[12] = s_in[12];

        // Linha 1: deslocamento circular de 1 byte à direita
        s_out[1]  = s_in[13];
        s_out[5]  = s_in[1];
        s_out[9]  = s_in[5];
        s_out[13] = s_in[9];

        // Linha 2: deslocamento circular de 2 bytes à direita
        s_out[2]  = s_in[10];
        s_out[6]  = s_in[14];
        s_out[10] = s_in[2];
        s_out[14] = s_in[6];

        // Linha 3: deslocamento circular de 3 bytes à direita
        s_out[3]  = s_in[7];
        s_out[7]  = s_in[11];
        s_out[11] = s_in[15];
        s_out[15] = s_in[3];

        for (int i = 0; i < 16; i++) begin
            state_out[127 - 8*i -: 8] = s_out[i];
        end
    end

endmodule