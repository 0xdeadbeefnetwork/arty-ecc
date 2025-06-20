// ============================================================================
// FIXED ECC SCALAR MULTIPLICATION SYSTEM FOR SECP256K1
// ============================================================================

// Fixed mod_mul.v - Proper serialized modular multiplication
module mod_mul (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [255:0] a,
    input  wire [255:0] b,
    output reg  [255:0] result,
    output reg         done
);
    localparam P = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    reg [511:0] product;
    reg [255:0] a_reg, b_reg;
    reg [8:0] bit_count;
    reg [2:0] state;

    always @(posedge clk) begin
        if (rst) begin
            product <= 0;
            result <= 0;
            done <= 0;
            bit_count <= 0;
            state <= 0;
        end else begin
            case (state)
                0: if (start) begin
                    a_reg <= a;
                    b_reg <= b;
                    product <= 0;
                    bit_count <= 0;
                    done <= 0;
                    state <= 1;
                end
                
                1: begin // Shift-and-add multiplication
                    if (bit_count < 256) begin
                        if (a_reg[0])
                            product <= product + ({256'b0, b_reg} << bit_count);
                        a_reg <= a_reg >> 1;
                        bit_count <= bit_count + 1;
                    end else begin
                        state <= 2;
                    end
                end
                
                2: begin // Modular reduction
                    if (product >= {256'b0, P})
                        product <= product - {256'b0, P};
                    else begin
                        result <= product[255:0];
                        done <= 1;
                        state <= 0;
                    end
                end
            endcase
        end
    end
endmodule