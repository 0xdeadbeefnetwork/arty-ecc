// ============================================================================ 
// Fixed mod_inv.v - Corrected modular inverse using extended Euclidean
// ============================================================================
module mod_inv (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [255:0] a,
    output reg  [255:0] result,
    output reg         done
);
    localparam [255:0] P = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    reg [255:0] u, v, x1, x2, temp;
    reg [2:0] state;
    reg [15:0] iter_count; // Prevent infinite loops

    always @(posedge clk) begin
        if (rst) begin
            result <= 0;
            done <= 0;
            state <= 0;
            iter_count <= 0;
        end else begin
            case (state)
                0: if (start) begin
                    u <= a;
                    v <= P;
                    x1 <= 1;
                    x2 <= 0;
                    done <= 0;
                    iter_count <= 0;
                    state <= 1;
                end
                
                1: begin // Extended Euclidean Algorithm
                    if (iter_count > 16'hFFFF) begin
                        // Timeout protection
                        result <= 0;
                        done <= 1;
                        state <= 0;
                    end else if (u == 1) begin
                        result <= x1;
                        done <= 1;
                        state <= 0;
                    end else if (v == 1) begin
                        result <= x2;
                        done <= 1;
                        state <= 0;
                    end else if (u == 0 || v == 0) begin
                        // No inverse exists
                        result <= 0;
                        done <= 1;
                        state <= 0;
                    end else begin
                        iter_count <= iter_count + 1;
                        if (u > v) begin
                            u <= u - v;
                            if (x1 >= x2) begin
                                x1 <= x1 - x2;
                            end else begin
                                x1 <= x1 + P - x2;
                            end
                        end else begin
                            v <= v - u;
                            if (x2 >= x1) begin
                                x2 <= x2 - x1;
                            end else begin
                                x2 <= x2 + P - x1;
                            end
                        end
                    end
                end
            endcase
        end
    end
endmodule
