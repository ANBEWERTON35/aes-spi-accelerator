module minisoc_aes_mix_columns (
    input  logic [127:0] state_in,
    output logic [127:0] state_out
);

    function automatic logic [7:0] xtime(input logic [7:0] b);
        xtime = {b[6:0], 1'b0} ^ (b[7] ? 8'h1b : 8'h00);
    endfunction

    function automatic logic [7:0] mul2(input logic [7:0] b);
        mul2 = xtime(b);
    endfunction

    function automatic logic [7:0] mul3(input logic [7:0] b);
        mul3 = xtime(b) ^ b;
    endfunction

    always_comb begin
        logic [7:0] s0, s1, s2, s3;
        logic [7:0] r0, r1, r2, r3;

        for (int c = 0; c < 4; c++) begin
            s0 = state_in[127 - (32*c +  0) -: 8];
            s1 = state_in[127 - (32*c +  8) -: 8];
            s2 = state_in[127 - (32*c + 16) -: 8];
            s3 = state_in[127 - (32*c + 24) -: 8];

            r0 = mul2(s0) ^ mul3(s1) ^ s2       ^ s3;
            r1 = s0       ^ mul2(s1) ^ mul3(s2) ^ s3;
            r2 = s0       ^ s1       ^ mul2(s2) ^ mul3(s3);
            r3 = mul3(s0) ^ s1       ^ s2       ^ mul2(s3);

            state_out[127 - (32*c +  0) -: 8] = r0;
            state_out[127 - (32*c +  8) -: 8] = r1;
            state_out[127 - (32*c + 16) -: 8] = r2;
            state_out[127 - (32*c + 24) -: 8] = r3;
        end
    end

endmodule