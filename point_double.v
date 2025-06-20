module point_double (
    input  wire        clk,
    input  wire        start,
    input  wire [255:0] X1,
    input  wire [255:0] Y1,
    input  wire [255:0] Z1,
    output reg  [255:0] X3,
    output reg  [255:0] Y3,
    output reg  [255:0] Z3,
    output reg         done
);

    localparam P = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    reg [4:0] state;

    // Temporary operands
    reg [255:0] a, b;
    wire [255:0] mul_result;
    wire mul_done;
    reg start_mul;

    // Internal intermediates
    reg [255:0] Y1_sq, X1_sq, S, M, M_sq, T, Z3_tmp, X3_tmp, Y3_tmp;

    mod_mul mul_inst (
        .clk(clk),
        .rst(1'b0),
        .start(start_mul),
        .a(a),
        .b(b),
        .result(mul_result),
        .done(mul_done)
    );

    always @(posedge clk) begin
        case (state)
            0: if (start) begin
                done <= 0;
                // Y1^2
                a <= Y1; b <= Y1;
                start_mul <= 1;
                state <= 1;
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
                    a <= mul_result; b <= 256'd4;
                    start_mul <= 1;
                    state <= 3;
                end
            end

            3: begin
                start_mul <= 0;
                if (mul_done) begin
                    S <= mul_result;
                    // X1^2
                    a <= X1; b <= X1;
                    start_mul <= 1;
                    state <= 4;
                end
            end

            4: begin
                start_mul <= 0;
                if (mul_done) begin
                    X1_sq <= mul_result;
                    // M = 3 * X1^2
                    a <= mul_result; b <= 256'd3;
                    start_mul <= 1;
                    state <= 5;
                end
            end

            5: begin
                start_mul <= 0;
                if (mul_done) begin
                    M <= mul_result;
                    // M^2
                    a <= mul_result; b <= mul_result;
                    start_mul <= 1;
                    state <= 6;
                end
            end

            6: begin
                start_mul <= 0;
                if (mul_done) begin
                    M_sq <= mul_result;
                    // T = Y1^4
                    a <= Y1_sq; b <= Y1_sq;
                    start_mul <= 1;
                    state <= 7;
                end
            end

            7: begin
                start_mul <= 0;
                if (mul_done) begin
                    T <= mul_result;
                    // Z3 = 2 * Y1 * Z1
                    a <= Y1; b <= Z1;
                    start_mul <= 1;
                    state <= 8;
                end
            end

            8: begin
                start_mul <= 0;
                if (mul_done) begin
                    a <= mul_result; b <= 256'd2;
                    start_mul <= 1;
                    state <= 9;
                end
            end

            9: begin
                start_mul <= 0;
                if (mul_done) begin
                    Z3_tmp <= mul_result;
                    // X3 = M^2 - 2*S
                    a <= S; b <= 256'd2;
                    start_mul <= 1;
                    state <= 10;
                end
            end

            10: begin
                start_mul <= 0;
                if (mul_done) begin
                    if (M_sq >= mul_result)
                        X3_tmp <= M_sq - mul_result;
                    else
                        X3_tmp <= M_sq + P - mul_result;

                    // S - X3
                    a <= S; b <= X3_tmp;
                    start_mul <= 1;
                    state <= 11;
                end
            end

            11: begin
                start_mul <= 0;
                if (mul_done) begin
                    // Y3 = M * (S - X3)
                    a <= M; b <= mul_result;
                    start_mul <= 1;
                    state <= 12;
                end
            end

            12: begin
                start_mul <= 0;
                if (mul_done) begin
                    if (mul_result >= (T << 3))
                        Y3_tmp <= mul_result - (T << 3);
                    else
                        Y3_tmp <= mul_result + P - (T << 3);

                    X3 <= X3_tmp;
                    Y3 <= Y3_tmp;
                    Z3 <= Z3_tmp;
                    done <= 1;
                    state <= 0;
                end
            end
        endcase
    end
endmodule
