// ============================================================================
// Test bench for verification 
// ============================================================================
module tb_ecc_system;
    reg clk;
    reg rst;
    reg start;
    reg [255:0] priv_key;
    wire [255:0] pub_x, pub_y;
    wire done;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock for simulation
    end

    // ECC instance
    ecc_scalar_mul uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .priv_key(priv_key),
        .pub_x(pub_x),
        .pub_y(pub_y),
        .done(done)
    );

    // Test vectors - known Bitcoin private/public key pairs
    initial begin
        $dumpfile("ecc_test.vcd");
        $dumpvars(0, tb_ecc_system);

        // Initialize
        rst = 1;
        start = 0;
        priv_key = 0;
        #100;
        rst = 0;
        #50;

        // Test 1: First key in puzzle range (2^71)
        $display("Testing private key = 2^71 (start of puzzle #72)");
        priv_key = 256'h0000000000000000000000000000000000000000000080000000000000000000;
        start = 1;
        #10;
        start = 0;
        
        wait(done);
        $display("Private key:  %064h", priv_key);
        $display("Public key X: %064h", pub_x);
        $display("Public key Y: %064h", pub_y);
        #100;

        // Test 2: Second key in range (2^71 + 1)
        $display("\nTesting private key = 2^71 + 1");
        priv_key = 256'h0000000000000000000000000000000000000000000080000000000000000001;
        start = 1;
        #10;
        start = 0;
        
        wait(done);
        $display("Private key:  %064h", priv_key);
        $display("Public key X: %064h", pub_x);
        $display("Public key Y: %064h", pub_y);
        #100;

        // Test 3: Random key in middle of range
        $display("\nTesting random key in puzzle range");
        priv_key = 256'h00000000000000000000000000000000000000000000800123456789ABCDEF00;
        start = 1;
        #10;
        start = 0;
        
        wait(done);
        $display("Private key:  %064h", priv_key);
        $display("Public key X: %064h", pub_x);
        $display("Public key Y: %064h", pub_y);
        #100;

        $display("\nSimulation completed");
        $finish;
    end

    // Timeout protection
    initial begin
        #500000; // Large timeout for ECC calculation
        $display("ERROR: Simulation timed out");
        $finish;
    end

endmodule
