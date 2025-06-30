// ============================================================================
// Fixed jacobian_to_affine.v - Corrected coordinate conversion
// ============================================================================
module jacobian_to_affine (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [255:0] Xj, Yj, Zj,
    output reg  [255:0] x_affine, y_affine,
    output reg         done
);

    reg [3:0] state;
    reg [255:0] z_inv, z2, z3;
    reg [255:0] mul_a, mul_b;
    reg start_mul, start_inv;

    wire [255:0] mul_result, inv_result;
    wire mul_done, inv_done;

    mod_inv inv_inst (
        .clk(clk), .rst(rst), .start(start_inv), 
        .a(Zj), .result(inv_result), .done(inv_done)
    );
    
    mod_mul mul_inst (
        .clk(clk), .rst(rst), .start(start_mul), 
        .a(mul_a), .b(mul_b), .result(mul_result), .done(mul_done)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= 0;
            done <= 0;
            start_mul <= 0;
            start_inv <= 0;
        end else begin
            case (state)
                0: if (start) begin
                    done <= 0;
                    if (Zj == 0) begin
                        // Point at infinity
                        x_affine <= 0;
                        y_affine <= 0;
                        done <= 1;
                    end else if (Zj == 1) begin
                        // Already affine
                        x_affine <= Xj;
                        y_affine <= Yj;
                        done <= 1;
                    end else begin
                        start_inv <= 1;
                        state <= 1;
                    end
                end
                
                1: begin
                    start_inv <= 0;
                    if (inv_done) begin
                        z_inv <= inv_result;
                        mul_a <= inv_result; 
                        mul_b <= inv_result;
                        start_mul <= 1;
                        state <= 2;
                    end
                end
                
                2: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        z2 <= mul_result;
                        mul_a <= mul_result; 
                        mul_b <= z_inv;
                        start_mul <= 1;
                        state <= 3;
                    end
                end
                
                3: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        z3 <= mul_result;
                        mul_a <= Xj; 
                        mul_b <= z2;
                        start_mul <= 1;
                        state <= 4;
                    end
                end
                
                4: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        x_affine <= mul_result;
                        mul_a <= Yj; 
                        mul_b <= z3;
                        start_mul <= 1;
                        state <= 5;
                    end
                end
                
                5: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        y_affine <= mul_result;
                        done <= 1;
                        state <= 0;
                    end
                end
            endcase
        end
    end
endmodule
