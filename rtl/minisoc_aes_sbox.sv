module minisoc_aes_sbox (
    input  logic [7:0] in_byte,
    output logic [7:0] out_byte
);

    function automatic logic [7:0] gf_mul(
        input logic [7:0] a,
        input logic [7:0] b
    );
        int i;
        logic [7:0] a_reg;
        logic [7:0] b_reg;
        logic [7:0] prod;
        begin
            a_reg = a;
            b_reg = b;
            prod  = 8'h00;
            for (i = 0; i < 8; i = i + 1) begin
                if (b_reg[0]) begin
                    prod = prod ^ a_reg;
                end
                a_reg = {a_reg[6:0], 1'b0} ^ (a_reg[7] ? 8'h1b : 8'h00);
                b_reg = {1'b0, b_reg[7:1]};
            end
            return prod;
        end
    endfunction

    function automatic logic [7:0] gf_inv(input logic [7:0] x);
        logic [7:0] x2, x4, x8, x16, x32, x64, x128;
        begin
            x2   = gf_mul(x, x);
            x4   = gf_mul(x2, x2);
            x8   = gf_mul(x4, x4);
            x16  = gf_mul(x8, x8);
            x32  = gf_mul(x16, x16);
            x64  = gf_mul(x32, x32);
            x128 = gf_mul(x64, x64);
            return gf_mul(gf_mul(gf_mul(gf_mul(gf_mul(gf_mul(x2, x4), x8), x16), x32), x64), x128);
        end
    endfunction

    logic [7:0] inv;

    always_comb begin
        inv = gf_inv(in_byte);
        out_byte = inv
                 ^ {inv[6:0], inv[7]}
                 ^ {inv[5:0], inv[7:6]}
                 ^ {inv[4:0], inv[7:5]}
                 ^ {inv[3:0], inv[7:4]}
                 ^ 8'h63;
    end

endmodule