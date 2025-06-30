// ============================================================================
// Fixed top.v - Bitcoin Puzzle #72 Key Generator (2^71 to 2^72-1)
// Generates private keys in range and outputs PrivateKey:PublicKeyX via UART
// ============================================================================
module top (
    input wire CLK12MHZ,
    input wire [3:0] btn,
    output wire uart_rxd_out,
    output wire [3:0] led
);

    wire clk_bufg;
    BUFG clk_bufg_inst (.I(CLK12MHZ), .O(clk_bufg));

    localparam BAUD_DIV = 104; // 12MHz / 115200 ≈ 104
    
    reg [23:0] heartbeat_counter = 0;
    reg heartbeat_led = 0;

    // Bitcoin puzzle range: 2^71 to 2^72-1 (72-bit entropy)
    // Format: 184 leading zeros + 72 bits of entropy
    localparam [255:0] PUZZLE_BASE = 256'h0000000000000000000000000000000000000000000080000000000000000000; // 2^71
    localparam [71:0] MAX_ENTROPY = 72'hFFFFFFFFFFFFFFFFFF; // 2^72 - 1
    
    // Starting offset - modify this to start from a specific point in the range
    // Example: 72'h123456789ABCDEF0 to start from a specific offset
    localparam [71:0] START_OFFSET = 72'h0; // Start from beginning of range
    
    reg [71:0] entropy_counter = START_OFFSET; // 72-bit counter for the entropy portion
    reg [255:0] priv_key;

    wire [255:0] pub_x, pub_y;
    wire ecc_done;
    reg ecc_start = 0;
    reg ecc_start_prev = 0;

    // UART transmission
    reg [8:0] tx_data = 9'h1FF; // Idle high
    reg [15:0] baud_counter = 0;
    reg [3:0] bit_counter = 0;
    reg tx_active = 0;
    
    // Message formatting
    reg [7:0] message [0:129]; // 64 private + 1 colon + 64 public X + newline
    reg [7:0] char_index = 0;
    reg [1:0] tx_state = 0;
    reg message_ready = 0;
    
    // Loop variable declaration (must be at module level)
    integer i;

    // ECC core instance
    ecc_scalar_mul ecc_core (
        .clk(clk_bufg),
        .rst(btn[0]), // Reset button
        .start(ecc_start),
        .priv_key(priv_key),
        .pub_x(pub_x),
        .pub_y(pub_y),
        .done(ecc_done)
    );

    // Generate private key from entropy counter
    always @(*) begin
        priv_key = PUZZLE_BASE | {184'b0, entropy_counter}; // Combine base with entropy
    end

    // Heartbeat LED
    always @(posedge clk_bufg) begin
        heartbeat_counter <= heartbeat_counter + 1;
        if (heartbeat_counter == 24'h5FFFFF) begin // ~0.5Hz at 12MHz
            heartbeat_led <= ~heartbeat_led;
            heartbeat_counter <= 0;
        end
    end

    // Hex conversion function
    function [7:0] nibble_to_hex;
        input [3:0] nib;
        begin
            nibble_to_hex = (nib < 10) ? (nib + 8'd48) : (nib + 8'd55); // '0'-'9', 'A'-'F'
        end
    endfunction

    // Main control logic
    always @(posedge clk_bufg) begin
        if (btn[0]) begin // Reset
            ecc_start <= 0;
            tx_state <= 0;
            tx_active <= 0;
            message_ready <= 0;
            char_index <= 0;
            entropy_counter <= START_OFFSET; // Reset to starting offset
        end else begin
            ecc_start_prev <= ecc_start;
            
            case (tx_state)
                0: begin // Idle - trigger ECC calculation
                    if (!ecc_start && !ecc_done) begin
                        ecc_start <= 1;
                        tx_state <= 1;
                    end
                end
                
                1: begin // Wait for ECC completion
                    ecc_start <= 0;
                    if (ecc_done) begin
                        // Format private key + public key as hex string
                        // First 64 chars: private key
                        for (i = 0; i < 64; i = i + 1) begin
                            message[i] <= nibble_to_hex(priv_key[255 - i*4 -: 4]);
                        end
                        message[64] <= 8'h3A; // Colon separator
                        // Next 64 chars: public key X coordinate
                        for (i = 0; i < 64; i = i + 1) begin
                            message[65 + i] <= nibble_to_hex(pub_x[255 - i*4 -: 4]);
                        end
                        message[129] <= 8'h0A; // Line feed
                        
                        char_index <= 0;
                        message_ready <= 1;
                        tx_state <= 2;
                    end
                end
                
                2: begin // Transmit message
                    if (message_ready && !tx_active && char_index <= 129) begin
                        // Load character into shift register (LSB first)
                        tx_data <= {message[char_index], 1'b0}; // Add start bit
                        tx_active <= 1;
                        bit_counter <= 0;
                        baud_counter <= 0;
                        char_index <= char_index + 1;
                    end else if (char_index > 129) begin
                        // Message complete, increment entropy and restart
                        message_ready <= 0;
                        if (entropy_counter == MAX_ENTROPY) begin
                            entropy_counter <= START_OFFSET; // Wrap back to start offset
                        end else begin
                            entropy_counter <= entropy_counter + 1;
                        end
                        tx_state <= 0;
                    end
                end
            endcase
        end
    end

    // UART bit timing and transmission
    always @(posedge clk_bufg) begin
        if (btn[0]) begin
            baud_counter <= 0;
            bit_counter <= 0;
            tx_active <= 0;
            tx_data <= 9'h1FF;
        end else if (tx_active) begin
            if (baud_counter < BAUD_DIV - 1) begin
                baud_counter <= baud_counter + 1;
            end else begin
                baud_counter <= 0;
                tx_data <= {1'b1, tx_data[8:1]}; // Shift right, fill with stop bit
                bit_counter <= bit_counter + 1;
                
                if (bit_counter == 9) begin // 1 start + 8 data + 1 stop = 10 bits
                    tx_active <= 0;
                    tx_data <= 9'h1FF; // Return to idle
                end
            end
        end
    end

    // Output assignments
    assign uart_rxd_out = tx_data[0];
    assign led[0] = heartbeat_led;
    assign led[1] = ecc_start;
    assign led[2] = tx_active;
    assign led[3] = ecc_done;

endmodule
