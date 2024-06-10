// Add cache to dmem.v module created by Sarah and David Harris.

module dmem(
    input clk, we,
    input [31:0] a, wd,
    output reg [31:0] rd
);
    reg [31:0] RAM[63:0];

    reg [31:0] CACHE[63:0];
    reg VALID [63:0];
    reg [23:0] TAG[63:0];

    integer index; // cache index
    integer read_hit = 0;
    integer write_hit = 0;

    initial begin
        $readmemh("initialvalues.txt", RAM);
        for (integer i = 0; i < 64; i = i + 1) begin 
            CACHE[i] = 32'b0;
            VALID[i] = 1'b0;
            TAG[i] = 24'b0;
        end
    end

    always @(*) begin 
        index = a[7:2]; // byte offset
        read_hit = (VALID[index] === 1'b1) && (TAG[index] == a[31:8]) && !we;
        write_hit = (VALID[index] === 1'b1) && (TAG[index] == a[31:8]) && we;

        if (write_hit == 0) begin // write miss...
            VALID[index] <= 1;
            TAG[index] <= a[31:8];
        end

        if (read_hit == 1) begin // read hit ...
            rd = CACHE[index];
        end else begin // read miss ...
            if (read_hit == 0) begin
                VALID[index] = 1;
                TAG[index] = a[31:8];
                CACHE[index] = RAM[a[31:2]];
                rd = CACHE[index];
            end
        end
    end

    always @(posedge clk) begin
        if (we == 1) begin // common procedure of write hit/miss
            CACHE[index] <= wd;
            RAM[a[31:2]] <= wd;
        end
    end
endmodule
