// ============================================================================
// Fixed point_double.v - Corrected Jacobian point doubling
// ============================================================================
module point_double (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [255:0] X1, Y1, Z1,
    output reg  [255:0] X3, Y3, Z3,
    output reg         done
);
    localparam [255:0] P = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    reg [4:0] state;
    reg [255:0] a, b;
    wire [255:0] mul_result;
    wire mul_done;
    reg start_mul;

    // Intermediate values for point doubling
    reg [255:0] Y1_sq, X1_sq, S, M, M_sq, T;

    mod_mul mul_inst (
        .clk(clk), .rst(rst), .start(start_mul),
        .a(a), .b(b), .result(mul_result), .done(mul_done)
    );

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
                    if (Z1 == 0) begin
                        // Doubling point at infinity = point at infinity
                        X3 <= 0; Y3 <= 1; Z3 <= 0;
                        done <= 1;
                    end else begin
                        // Y1^2
                        a <= Y1; b <= Y1;
                        start_mul <= 1;
                        state <= 1;
                    end
                end

                1: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        Y1_sq <= mul_result;
                        // S = 4 * X1 * Y1^2  
                        a <= X1; b <= mul_result;
                        start_mul <= 1;
                        state <= 2;
                    end
                end

                2: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        // Multiply by 4
                        S <= (mul_result << 2) % P;
                        // X1^2
                        a <= X1; b <= X1;
                        start_mul <= 1;
                        state <= 3;
                    end
                end

                3: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        X1_sq <= mul_result;
                        // M = 3 * X1^2 (secp256k1 has a=0)
                        M <= ((mul_result << 1) + mul_result) % P;
                        // M^2 calculation starts
                        a <= ((mul_result << 1) + mul_result) % P;
                        b <= ((mul_result << 1) + mul_result) % P;
                        start_mul <= 1;
                        state <= 4;
                    end
                end

                4: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        M_sq <= mul_result;
                        // T = 8 * Y1^4
                        a <= Y1_sq; b <= Y1_sq;
                        start_mul <= 1;
                        state <= 5;
                    end
                end

                5: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        T <= (mul_result << 3) % P;
                        // X3 = M^2 - 2*S
                        X3 <= mod_sub(M_sq, (S << 1) % P);
                        // Z3 = 2 * Y1 * Z1
                        a <= Y1; b <= Z1;
                        start_mul <= 1;
                        state <= 6;
                    end
                end

                6: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        Z3 <= (mul_result << 1) % P;
                        // Y3 = M * (S - X3) - T
                        a <= M; b <= mod_sub(S, X3);
                        start_mul <= 1;
                        state <= 7;
                    end
                end

                7: begin
                    start_mul <= 0;
                    if (mul_done) begin
                        Y3 <= mod_sub(mul_result, T);
                        done <= 1;
                        state <= 0;
                    end
                end
            endcase
        end
    end
endmodule
