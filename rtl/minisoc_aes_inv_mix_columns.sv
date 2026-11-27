module minisoc_aes_inv_mix_columns (
    input  logic [127:0] state_in,
    output logic [127:0] state_out
);

    function automatic logic [7:0] xtime(input logic [7:0] b);
        xtime = {b[6:0], 1'b0} ^ (b[7] ? 8'h1b : 8'h00);
    endfunction

    function automatic logic [7:0] mul2(input logic [7:0] b);
        mul2 = xtime(b);
    endfunction

    function automatic logic [7:0] mul4(input logic [7:0] b);
        mul4 = xtime(mul2(b));
    endfunction

    function automatic logic [7:0] mul8(input logic [7:0] b);
        mul8 = xtime(mul4(b));
    endfunction

    function automatic logic [7:0] mul9(input logic [7:0] b);
        mul9 = mul8(b) ^ b;
    endfunction

    function automatic logic [7:0] mulb(input logic [7:0] b);
        mulb = mul8(b) ^ mul2(b) ^ b;
    endfunction

    function automatic logic [7:0] muld(input logic [7:0] b);
        muld = mul8(b) ^ mul4(b) ^ b;
    endfunction

    function automatic logic [7:0] mule(input logic [7:0] b);
        mule = mul8(b) ^ mul4(b) ^ mul2(b);
    endfunction

    always_comb begin
        logic [7:0] s0, s1, s2, s3;
        logic [7:0] r0, r1, r2, r3;

        for (int c = 0; c < 4; c++) begin
            s0 = state_in[127 - (32*c +  0) -: 8];
            s1 = state_in[127 - (32*c +  8) -: 8];
            s2 = state_in[127 - (32*c + 16) -: 8];
            s3 = state_in[127 - (32*c + 24) -: 8];

            r0 = mule(s0) ^ mulb(s1) ^ muld(s2) ^ mul9(s3);
            r1 = mul9(s0) ^ mule(s1) ^ mulb(s2) ^ muld(s3);
            r2 = muld(s0) ^ mul9(s1) ^ mule(s2) ^ mulb(s3);
            r3 = mulb(s0) ^ muld(s1) ^ mul9(s2) ^ mule(s3);

            state_out[127 - (32*c +  0) -: 8] = r0;
            state_out[127 - (32*c +  8) -: 8] = r1;
            state_out[127 - (32*c + 16) -: 8] = r2;
            state_out[127 - (32*c + 24) -: 8] = r3;
        end
    end

endmodule