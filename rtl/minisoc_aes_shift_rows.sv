module minisoc_aes_shift_rows (
    input  logic [127:0] state_in,
    output logic [127:0] state_out
);

    // Definição dos bytes de entrada (apenas para clareza visual no mapeamento)
    // Linha 0: 0, 4, 8, 12  -> Deslocamento 0
    // Linha 1: 1, 5, 9, 13  -> Deslocamento 1
    // Linha 2: 2, 6, 10, 14 -> Deslocamento 2
    // Linha 3: 3, 7, 11, 15 -> Deslocamento 3

    assign state_out = {
        // Linha 0 (Sem deslocamento)
        state_in[127:120], // Byte 0 -> 0
        
        // Linha 1 (Desloca 1 byte para a esquerda)
        state_in[87:80],   // Byte 5 -> 1
        
        // Linha 2 (Desloca 2 bytes para a esquerda)
        state_in[47:40],   // Byte 10 -> 2
        
        // Linha 3 (Desloca 3 bytes para a esquerda)
        state_in[7:0],     // Byte 15 -> 3
        
        // Coluna 1
        state_in[95:88],   // Byte 4 -> 4
        state_in[55:48],   // Byte 9 -> 5
        state_in[15:8],    // Byte 14 -> 6
        state_in[103:96],  // Byte 3 -> 7
        
        // Coluna 2
        state_in[63:56],   // Byte 8 -> 8
        state_in[23:16],   // Byte 13 -> 9
        state_in[111:104], // Byte 2 -> 10
        state_in[71:64],   // Byte 7 -> 11
        
        // Coluna 3
        state_in[31:24],   // Byte 12 -> 12
        state_in[119:112], // Byte 1 -> 13
        state_in[79:72],   // Byte 6 -> 14
        state_in[39:32]    // Byte 11 -> 15
    };

endmodule