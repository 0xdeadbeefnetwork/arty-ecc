// ============================================================================
// CORRECTED ECC SCALAR MULTIPLICATION SYSTEM FOR SECP256K1
// Generates valid Bitcoin public keys from private keys
// ============================================================================

// Fixed ecc_scalar_mul.v - Proper binary scalar multiplication
module ecc_scalar_mul (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [255:0] priv_key,
    output reg  [255:0] pub_x,
    output reg  [255:0] pub_y,
    output reg         done
);

    // secp256k1 Base Point G
    localparam [255:0] Gx = 256'h79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    localparam [255:0] Gy = 256'h483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;

    // FSM states
    localparam [2:0] IDLE = 0, INIT = 1, DOUBLE = 2, ADD = 3, FINISH = 4;

    reg [2:0] state;
    reg [8:0] bit_index; // 9 bits to handle 255 down to 0
    reg first_one_found;

    // Working point R (in Jacobian coordinates)
    reg [255:0] Rx, Ry, Rz;

    // Point doubling interface
    wire [255:0] dx, dy, dz;
    wire d_done;
    reg  d_start;

    // Point addition interface  
    wire [255:0] ax, ay, az;
    wire a_done;
    reg  a_start;

    // Jacobian to affine conversion interface
    wire [255:0] aff_x, aff_y;
    wire j_done;
    reg  j_start;

    point_double pd (
        .clk(clk),
        .rst(rst),
        .start(d_start),
        .X1(Rx), .Y1(Ry), .Z1(Rz),
        .X3(dx), .Y3(dy), .Z3(dz),
        .done(d_done)
    );

    point_add pa (
        .clk(clk),
        .rst(rst), 
        .start(a_start),
        .X1(Rx), .Y1(Ry), .Z1(Rz),
        .X2(Gx), .Y2(Gy), .Z2(256'd1),
        .X3(ax), .Y3(ay), .Z3(az),
        .done(a_done)
    );

    jacobian_to_affine ja (
        .clk(clk),
        .rst(rst),
        .start(j_start),
        .Xj(Rx), .Yj(Ry), .Zj(Rz),
        .x_affine(aff_x), .y_affine(aff_y),
        .done(j_done)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            d_start <= 0;
            a_start <= 0; 
            j_start <= 0;
            done <= 0;
            pub_x <= 0;
            pub_y <= 0;
            bit_index <= 255;
            first_one_found <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        // Start with point at infinity (identity element)
                        Rx <= 0; Ry <= 1; Rz <= 0; // Point at infinity in Jacobian
                        bit_index <= 255;
                        first_one_found <= 0;
                        state <= INIT;
                    end
                end

                INIT: begin
                    // Find first '1' bit from MSB (skip leading zeros)
                    if (priv_key[bit_index] == 1'b1) begin
                        // First '1' found - initialize R = G
                        Rx <= Gx;
                        Ry <= Gy; 
                        Rz <= 256'd1;
                        first_one_found <= 1;
                        if (bit_index == 0) begin
                            state <= FINISH; // Single bit case
                        end else begin
                            bit_index <= bit_index - 1;
                            state <= DOUBLE;
                        end
                    end else if (bit_index == 0) begin
                        // All zeros - invalid private key, return zero point
                        pub_x <= 0;
                        pub_y <= 0;
                        done <= 1;
                        state <= IDLE;
                    end else begin
                        bit_index <= bit_index - 1;
                    end
                end

                DOUBLE: begin
                    if (!d_start && !d_done) begin
                        d_start <= 1;
                    end else if (d_start && !d_done) begin
                        d_start <= 0;
                    end else if (d_done) begin
                        // Update R with doubled point
                        Rx <= dx;
                        Ry <= dy;
                        Rz <= dz;
                        
                        // Check if current bit is set
                        if (priv_key[bit_index]) begin
                            state <= ADD;
                        end else begin
                            if (bit_index == 0) begin
                                state <= FINISH;
                            end else begin
                                bit_index <= bit_index - 1;
                                state <= DOUBLE;
                            end
                        end
                    end
                end

                ADD: begin
                    if (!a_start && !a_done) begin
                        a_start <= 1;
                    end else if (a_start && !a_done) begin
                        a_start <= 0;
                    end else if (a_done) begin
                        // Update R with added point
                        Rx <= ax;
                        Ry <= ay;
                        Rz <= az;
                        
                        if (bit_index == 0) begin
                            state <= FINISH;
                        end else begin
                            bit_index <= bit_index - 1;
                            state <= DOUBLE;
                        end
                    end
                end

                FINISH: begin
                    if (!j_start && !j_done) begin
                        j_start <= 1;
                    end else if (j_start && !j_done) begin
                        j_start <= 0;
                    end else if (j_done) begin
                        pub_x <= aff_x;
                        pub_y <= aff_y;
                        done <= 1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule
