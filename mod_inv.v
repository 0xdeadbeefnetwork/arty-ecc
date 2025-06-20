// Fixed mod_inv.v - Extended Euclidean Algorithm
module mod_inv (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [255:0] a,
    output reg  [255:0] result,
    output reg         done
);
    localparam P = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    reg [255:0] u, v, x1, x2;
    reg [2:0] state;
    reg [255:0] temp;

    always @(posedge clk) begin
        if (rst) begin
            result <= 0;
            done <= 0;
            state <= 0;
        end else begin
            case (state)
                0: if (start) begin
                    u <= a;
                    v <= P;
                    x1 <= 1;
                    x2 <= 0;
                    done <= 0;
                    state <= 1;
                end
                
                1: begin // Extended Euclidean Algorithm
                    if (u == 1) begin
                        result <= x1;
                        done <= 1;
                        state <= 0;
                    end else if (v == 1) begin
                        result <= x2;
                        done <= 1;
                        state <= 0;
                    end else if (u > v) begin
                        u <= u - v;
                        x1 <= (x1 >= x2) ? x1 - x2 : x1 + P - x2;
                    end else begin
                        v <= v - u;
                        x2 <= (x2 >= x1) ? x2 - x1 : x2 + P - x1;
                    end
                end
            endcase
        end
    end
endmodule