module dummy_top (
    input  logic       clk,
    input  logic       rst_n,
    output logic [7:0] count
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 8'h00;
        end else begin
            count <= count + 1'b1;
        end
    end

endmodule