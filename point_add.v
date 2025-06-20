// Fixed point_add.v - Jacobian point addition
module point_add (
    input  wire        clk,
    input  wire        start,
    input  wire [255:0] X1, Y1, Z1,
    input  wire [255:0] X2, Y2, Z2,
    output reg  [255:0] X3, Y3, Z3,
    output reg         done
);
    localparam P = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    reg [4:0] state;
    reg [255:0] a, b;
    wire [255:0] mul_result;
    wire mul_done;
    reg start_mul;

    mod_mul mul_inst (.clk(clk), .rst(1'b0), .start(start_mul), 
                      .a(a), .b(b), .result(mul_result), .done(mul_done));

    reg [255:0] U1, U2, S1, S2, H, R, H2, H3, U1H2, S1H3;

    always @(posedge clk) begin
        case (state)
            0: if (start) begin
                done <= 0;
                a <= X1; b <= Z2;
                start_mul <= 1;
                state <= 1;
            end
            
            1: begin
                start_mul <= 0;
                if (mul_done) begin
                    U1 <= mul_result;
                    a <= X2; b <= Z1;
                    start_mul <= 1;
                    state <= 2;
                end
            end
            
            2: begin
                start_mul <= 0;
                if (mul_done) begin
                    U2 <= mul_result;
                    H <= (mul_result >= U1) ? mul_result - U1 : mul_result + P - U1;
                    a <= Y1; b <= Z2;
                    start_mul <= 1;
                    state <= 3;
                end
            end
            
            3: begin
                start_mul <= 0;
                if (mul_done) begin
                    S1 <= mul_result;
                    a <= Y2; b <= Z1;
                    start_mul <= 1;
                    state <= 4;
                end
            end
            
            4: begin
                start_mul <= 0;
                if (mul_done) begin
                    S2 <= mul_result;
                    R <= (mul_result >= S1) ? mul_result - S1 : mul_result + P - S1;
                    a <= H; b <= H;
                    start_mul <= 1;
                    state <= 5;
                end
            end
            
            5: begin
                start_mul <= 0;
                if (mul_done) begin
                    H2 <= mul_result;
                    a <= mul_result; b <= H;
                    start_mul <= 1;
                    state <= 6;
                end
            end
            
            6: begin
                start_mul <= 0;
                if (mul_done) begin
                    H3 <= mul_result;
                    a <= U1; b <= H2;
                    start_mul <= 1;
                    state <= 7;
                end
            end
            
            7: begin
                start_mul <= 0;
                if (mul_done) begin
                    U1H2 <= mul_result;
                    a <= S1; b <= H3;
                    start_mul <= 1;
                    state <= 8;
                end
            end
            
            8: begin
                start_mul <= 0;
                if (mul_done) begin
                    S1H3 <= mul_result;
                    a <= R; b <= R;
                    start_mul <= 1;
                    state <= 9;
                end
            end
            
            9: begin
                start_mul <= 0;
                if (mul_done) begin
                    // X3 = R^2 - H^3 - 2*U1*H^2
                    X3 <= ((mul_result >= H3) ? mul_result - H3 : mul_result + P - H3);
                    X3 <= ((X3 >= (U1H2 << 1)) ? X3 - (U1H2 << 1) : X3 + P - (U1H2 << 1)) % P;
                    
                    a <= (U1H2 >= X3) ? U1H2 - X3 : U1H2 + P - X3; b <= R;
                    start_mul <= 1;
                    state <= 10;
                end
            end
            
            10: begin
                start_mul <= 0;
                if (mul_done) begin
                    Y3 <= (mul_result >= S1H3) ? mul_result - S1H3 : mul_result + P - S1H3;
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
endmodule