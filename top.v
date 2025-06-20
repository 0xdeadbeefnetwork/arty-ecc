// Fixed UART section for top.v
module top (
    input wire CLK12MHZ,
    input wire [3:0] btn,
    output wire uart_rxd_out,
    output wire [3:0] led
);

    wire clk_bufg;
    BUFG clk_bufg_inst (.I(CLK12MHZ), .O(clk_bufg));

    localparam BAUD_DIV = 104; // 12MHz / 115200 ? 104
    reg [23:0] heartbeat_counter = 0;
    reg heartbeat_led = 0;

    // Auto-scanning private key
    reg [255:0] priv_key = 256'h0000000000000000000000000000000000000000000000800000000000000000;

    wire [255:0] pub_x;
    wire [255:0] pub_y;
    wire done;
    reg start = 0;

    reg [511:0] pubkey_concat;
    reg [7:0] message [0:128]; // Extra byte for newline
    integer i;

    // UART state machine
    reg [15:0] baud_counter = 0;
    reg [9:0] tx_shift = 10'b1111111111; // idle high
    reg [3:0] tx_bit_count = 0;
    reg tx_active = 0;
    reg [7:0] char_index = 0;
    reg transmit_message = 0;
    reg transmission_complete = 0;
    reg ecc_done_prev = 0;

    // ECC core
    ecc_scalar_mul ecc_core (
        .clk(clk_bufg),
        .rst(btn[1]),
        .start(start),
        .priv_key(priv_key),
        .pub_x(pub_x),
        .pub_y(pub_y),
        .done(done)
    );

    // Heartbeat
    always @(posedge clk_bufg) begin
        heartbeat_counter <= heartbeat_counter + 1;
        if (heartbeat_counter == 24'h7FFFFF) begin
            heartbeat_led <= ~heartbeat_led;
            heartbeat_counter <= 0;
        end
    end

    // Hex converter
    function [7:0] nibble_to_ascii;
        input [3:0] nib;
        begin
            nibble_to_ascii = (nib < 10) ? (nib + 8'd48) : (nib + 8'd87); // '0' = 48, 'a' = 97
        end
    endfunction

    // Main control logic
    always @(posedge clk_bufg) begin
        ecc_done_prev <= done;
        
        // Auto-trigger ECC if idle
        if (!start && !tx_active && !transmit_message && transmission_complete) begin
            start <= 1;
            transmission_complete <= 0;
        end else begin
            start <= 0;
        end

        // Detect ECC completion (rising edge)
        if (done && !ecc_done_prev) begin
            pubkey_concat <= {pub_x, pub_y};
            // Convert to hex ASCII
            for (i = 0; i < 128; i = i + 1) begin
                message[i] <= nibble_to_ascii(pubkey_concat[511 - i*4 -: 4]);
            end
            message[128] <= 8'h0A; // newline
            
            transmit_message <= 1;
            char_index <= 0;
        end

        // UART transmission state machine
        if (transmit_message && !tx_active) begin
            if (char_index <= 128) begin // Include newline
                // Load next character (LSB first format)
                tx_shift <= {1'b1, message[char_index][7], message[char_index][6], 
                            message[char_index][5], message[char_index][4], 
                            message[char_index][3], message[char_index][2], 
                            message[char_index][1], message[char_index][0], 1'b0};
                tx_bit_count <= 0;
                tx_active <= 1;
                baud_counter <= 0;
                char_index <= char_index + 1;
            end else begin
                // Transmission complete
                transmit_message <= 0;
                transmission_complete <= 1;
                priv_key <= priv_key + 1; // Next key
            end
        end

        // UART bit timing
        if (tx_active) begin
            if (baud_counter < BAUD_DIV - 1) begin
                baud_counter <= baud_counter + 1;
            end else begin
                baud_counter <= 0;
                tx_shift <= {1'b1, tx_shift[9:1]}; // Shift right, fill with 1
                tx_bit_count <= tx_bit_count + 1;
                if (tx_bit_count == 9) begin // All 10 bits sent
                    tx_active <= 0;
                end
            end
        end
    end

    assign uart_rxd_out = tx_active ? tx_shift[0] : 1'b1;
    assign led[0] = heartbeat_led;
    assign led[1] = start;
    assign led[2] = tx_active;
    assign led[3] = done;

endmodule