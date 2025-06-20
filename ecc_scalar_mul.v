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

    // FSM state encoding
    localparam IDLE = 0,
               INIT = 1,
               DOUBLE = 2,
               ADD = 3,
               FINISH = 4;

    reg [2:0] state;
    reg [7:0] bit_index;

    // Working point R (in Jacobian)
    reg [255:0] Rx, Ry, Rz;

    // G point in Jacobian
    wire [255:0] Gx_j = Gx;
    wire [255:0] Gy_j = Gy;
    wire [255:0] Gz_j = 256'd1;

    // Outputs from point_double
    wire [255:0] dx, dy, dz;
    wire d_done;
    reg  d_start;

    // Outputs from point_add
    wire [255:0] ax, ay, az;
    wire a_done;
    reg  a_start;

    // Outputs from jacobian_to_affine
    wire [255:0] aff_x, aff_y;
    wire j_done;
    reg  j_start;

    // Instantiate point doubling
    point_double pd (
        .clk(clk),
        .start(d_start),
        .X1(Rx),
        .Y1(Ry),
        .Z1(Rz),
        .X3(dx),
        .Y3(dy),
        .Z3(dz),
        .done(d_done)
    );

    // Instantiate point addition
    point_add pa (
        .clk(clk),
        .start(a_start),
        .X1(Rx),
        .Y1(Ry),
        .Z1(Rz),
        .X2(Gx_j),
        .Y2(Gy_j),
        .Z2(Gz_j),
        .X3(ax),
        .Y3(ay),
        .Z3(az),
        .done(a_done)
    );

    // Instantiate jacobian to affine converter
    jacobian_to_affine ja (
        .clk(clk),
        .start(j_start),
        .Xj(Rx),
        .Yj(Ry),
        .Zj(Rz),
        .x_affine(aff_x),
        .y_affine(aff_y),
        .done(j_done)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            d_start <= 0;
            a_start <= 0;
            j_start <= 0;
            done <= 0;
            pub_x <= 0;
            pub_y <= 0;
            Rx <= 0; Ry <= 0; Rz <= 0;
            bit_index <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        Rx <= Gx;
                        Ry <= Gy;
                        Rz <= 256'd1;
                        bit_index <= 254;
                        state <= DOUBLE;
                    end
                end

                DOUBLE: begin
                    d_start <= 1;
                    state <= DOUBLE + 1;
                end

                DOUBLE + 1: begin
                    d_start <= 0;
                    if (d_done) begin
                        Rx <= dx;
                        Ry <= dy;
                        Rz <= dz;
                        if (priv_key[bit_index]) begin
                            a_start <= 1;
                            state <= ADD;
                        end else begin
                            if (bit_index == 0)
                                state <= FINISH;
                            else begin
                                bit_index <= bit_index - 1;
                                state <= DOUBLE;
                            end
                        end
                    end
                end

                ADD: begin
                    a_start <= 0;
                    if (a_done) begin
                        Rx <= ax;
                        Ry <= ay;
                        Rz <= az;
                        if (bit_index == 0)
                            state <= FINISH;
                        else begin
                            bit_index <= bit_index - 1;
                            state <= DOUBLE;
                        end
                    end
                end

                FINISH: begin
                    j_start <= 1;
                    state <= FINISH + 1;
                end

                FINISH + 1: begin
                    j_start <= 0;
                    if (j_done) begin
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
