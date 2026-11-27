module minisoc_aes_inv_sbox (
    input  logic [7:0] in_byte,
    output logic [7:0] out_byte
);

    function automatic logic [7:0] gf_mul(input logic [7:0] a, input logic [7:0] b);
        logic [7:0] prod;
        logic [7:0] temp_a;
        prod   = 8'h00;
        temp_a = a;
        for (int i = 0; i < 8; i++) begin
            if (b[i]) begin
                prod ^= temp_a;
            end
            temp_a = {temp_a[6:0], 1'b0} ^ (temp_a[7] ? 8'h1b : 8'h00);
        end
        return prod;
    endfunction

    function automatic logic [7:0] gf_inv(input logic [7:0] x);
        logic [7:0] x2, x4, x8, x16, x32, x64, x128;
        x2   = gf_mul(x, x);
        x4   = gf_mul(x2, x2);
        x8   = gf_mul(x4, x4);
        x16  = gf_mul(x8, x8);
        x32  = gf_mul(x16, x16);
        x64  = gf_mul(x32, x32);
        x128 = gf_mul(x64, x64);
        return gf_mul(gf_mul(gf_mul(gf_mul(gf_mul(gf_mul(x2, x4), x8), x16), x32), x64), x128);
    endfunction

    logic [7:0] inv_aff;

    always_comb begin
        inv_aff  = {in_byte[6:0], in_byte[7]} ^
                   {in_byte[4:0], in_byte[7:5]} ^
                   {in_byte[1:0], in_byte[7:2]} ^
                   8'h05;
        out_byte = gf_inv(inv_aff);
    end

endmodule