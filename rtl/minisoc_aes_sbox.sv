module minisoc_aes_sbox (
    input  logic [7:0] in_byte,
    output logic [7:0] out_byte
);

    always_comb begin
        case (in_byte)
            8'h00: out_byte = 8'h63; 8'h01: out_byte = 8'h7c; 8'h02: out_byte = 8'h77; 8'h03: out_byte = 8'h7b;
            8'h04: out_byte = 8'hf2; 8'h05: out_byte = 8'h6b; 8'h06: out_byte = 8'h6f; 8'h07: out_byte = 8'hc5;
            8'h08: out_byte = 8'h30; 8'h09: out_byte = 8'h01; 8'h0a: out_byte = 8'h67; 8'h0b: out_byte = 8'h2b;
            8'h0c: out_byte = 8'hfe; 8'h0d: out_byte = 8'hd7; 8'h0e: out_byte = 8'hab; 8'h0f: out_byte = 8'h76;
            // ... (Para brevidade, a tabela completa de 256 valores deve ser preenchida aqui conforme FIPS-197)
            8'h53: out_byte = 8'hed;
            // ...
            default: out_byte = 8'h00; // Preencher tabela completa para lint sem erros
        endcase
    end

endmodule