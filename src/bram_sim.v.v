module bram_sim    
(
    input wire clk,
    input wire [n-1:0] addr,
    output reg [w-1:0] dout
);

parameter n = 4;
parameter w = 8;

    reg [w-1:0] ram[2**n-1];

    integer i;
    initial begin
        for(i = 0; i < 2**n - 1; i = i + 1) begin
            ram[i] <= i;
        end
    end

    always @(negedge clk) begin
        dout = ram[addr];
    end

endmodule
