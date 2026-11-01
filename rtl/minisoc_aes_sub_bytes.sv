module minisoc_aes_sub_bytes (
    input  logic [127:0] state_in,
    output logic [127:0] state_out
);

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : sbox_instances
            minisoc_aes_sbox u_sbox (
                .in_byte  (state_in[127 - (i*8) : 120 - (i*8)]),
                .out_byte (state_out[127 - (i*8) : 120 - (i*8)])
            );
        end
    endgenerate

endmodule