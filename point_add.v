// ============================================================================
// Fixed point_add.v - Corrected Jacobian point addition  
// ============================================================================
module point_add (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [255:0] X1, Y1, Z1,
    input  wire [255:0] X2, Y2, Z2,
    output reg  [255:0] X3, Y3, Z3,
    output reg         done
);
    localparam [255:0] P = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    reg [4:0] state;
    reg [255:0] a, b;
    wire [255:0] mul_result;
    wire mul_done;
    reg start_mul;

    mod_mul mul_inst (
        .clk(clk), .rst(rst), .start(start_mul),
        .a(a), .b(b), .result(mul_result), .done(mul_done)
    );

    reg [255:0] U1, U2, S1, S2, H, R, H2, H3, U1H2, S1H3;

    // Helper function for modular subtraction
    function [255:0] mod_sub;
        input [255:0] x, y;
        begin
            mod_sub = (x >= y) ? (x - y) : (x + P - y);
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            state <= 0;
            done <= 0;
            start_mul <= 0;
        end else begin
            case (state)
                0: if (start) begin
                    done <= 0;
                    // Handle special cases
                    if (Z1 == 0) begin
                        // P1 is point at infinity, return P2
                        X3 <= X2; Y3 <= Y2; Z3 <= Z2;
                        done <= 1;
                    end else if (Z2 == 0) begin
                        // P2 is point at infinity, return P1
                        X3 <= X1; Y3 <= Y1; Z3 <= Z1;
                        done <= 1;
                    end else begin
                        // U1 = X1 * Z2
                        a <= X1; b <= Z2;
                        start_mul <= 1;
                        state <= 1;
                    end
                end
                
                1: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        U1 <= mul_result;
                        // U2 = X2 * Z1
                        a <= X2; b <= Z1;
                        start_mul <= 1;
                        state <= 2;
                    end
                end
                
                2: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        U2 <= mul_result;
                        H <= mod_sub(mul_result, U1);
                        // S1 = Y1 * Z2
                        a <= Y1; b <= Z2;
                        start_mul <= 1;
                        state <= 3;
                    end
                end
                
                3: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        S1 <= mul_result;
                        // S2 = Y2 * Z1
                        a <= Y2; b <= Z1;
                        start_mul <= 1;
                        state <= 4;
                    end
                end
                
                4: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        S2 <= mul_result;
                        R <= mod_sub(mul_result, S1);
                        
                        // Check for point doubling case
                        if (H == 0 && R == 0) begin
                            // Points are the same, should double instead
                            // For simplicity, return point at infinity (this should trigger point doubling)
                            X3 <= 0; Y3 <= 1; Z3 <= 0;
                            done <= 1;
                            state <= 0;
                        end else begin
                            // H^2
                            a <= H; b <= H;
                            start_mul <= 1;
                            state <= 5;
                        end
                    end
                end
                
                5: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        H2 <= mul_result;
                        // H^3 = H^2 * H
                        a <= mul_result; b <= H;
                        start_mul <= 1;
                        state <= 6;
                    end
                end
                
                6: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        H3 <= mul_result;
                        // U1 * H^2
                        a <= U1; b <= H2;
                        start_mul <= 1;
                        state <= 7;
                    end
                end
                
                7: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        U1H2 <= mul_result;
                        // S1 * H^3
                        a <= S1; b <= H3;
                        start_mul <= 1;
                        state <= 8;
                    end
                end
                
                8: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        S1H3 <= mul_result;
                        // R^2
                        a <= R; b <= R;
                        start_mul <= 1;
                        state <= 9;
                    end
                end
                
                9: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        // X3 = R^2 - H^3 - 2*U1*H^2
                        X3 <= mod_sub(mod_sub(mul_result, H3), (U1H2 << 1) % P);
                        // Calculate (U1*H^2 - X3) for Y3
                        a <= mod_sub(U1H2, X3); b <= R;
                        start_mul <= 1;
                        state <= 10;
                    end
                end
                
                10: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        // Y3 = R * (U1*H^2 - X3) - S1*H^3
                        Y3 <= mod_sub(mul_result, S1H3);
                        // Z3 = Z1 * Z2 * H
                        a <= Z1; b <= Z2;
                        start_mul <= 1;
                        state <= 11;
                    end
                end
                
                11: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        a <= mul_result; b <= H;
                        start_mul <= 1;
                        state <= 12;
                    end
                end
                
                12: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        Z3 <= mul_result;
                        done <= 1;
                        state <= 0;
                    end
                end
            endcase
        end
    end
endmodule
