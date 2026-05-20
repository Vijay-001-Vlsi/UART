`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench : top_mod_tb
// Strategy  : TX and RX tested with SEPARATE data simultaneously.
//             TX  - drive xmitH + xmit_dataH, sample uart_XMIT_dataH bits
//             RX  - drive uart_REC_dataH manually (task), check rec_dataH
// Tests     : TX sends 0x55 | RX receives 0xA5  (at the same time)
//             TX sends 0xFF | RX receives 0x00  (at the same time)
//////////////////////////////////////////////////////////////////////////////////
module tb_main;

    // ── DUT ports ──────────────────────────────────
    reg        sys_clk;
    reg        sys_rst_l;

    // TX side
    reg        xmitH;
    reg  [7:0] xmit_dataH;
    wire       uart_XMIT_dataH;
    wire       xmit_doneH;
    wire       xmit_active;

    // RX side - driven manually by TB
    reg        uart_REC_dataH;
    wire [7:0] rec_dataH;
    wire       rec_readyH;
    wire       rec_busy;

    // ── DUT ────────────────────────────────────────
    top_mod #(
        .freq   (100),
        .b_rate (2),
        .width  (8)
    ) uut (
        .sys_clk         (sys_clk),
        .sys_rst_l       (sys_rst_l),
        .xmitH           (xmitH),
        .xmit_dataH      (xmit_dataH),
        .uart_XMIT_dataH (uart_XMIT_dataH),
        .xmit_doneH      (xmit_doneH),
        .xmit_active     (xmit_active),
        .uart_REC_dataH  (uart_REC_dataH),
        .rec_dataH       (rec_dataH),
        .rec_readyH      (rec_readyH),
        .rec_busy        (rec_busy)
    );

    // ── System clock : 10 ns (100 MHz) ─────────────
    initial sys_clk = 0;
    always #5 sys_clk = ~sys_clk;

    // ── Baud clock reference ───────────────────────
    wire b_clk;
    assign b_clk = uut.b_clk;

    // ──────────────────────────────────────────────
    //  TX CAPTURE
    //  Sample uart_XMIT_dataH at mid-bit (count==8)
    //  during data_trans state, LSB first.
    // ──────────────────────────────────────────────
    reg [7:0] tx_captured;
    reg [2:0] tx_bit_idx;

    always @(posedge b_clk) begin
        if (!sys_rst_l) begin
            tx_captured <= 8'd0;
            tx_bit_idx  <= 3'd0;
        end else begin
            if (uut.u_tx.ps == 2'd2) begin           // data_trans
                if (uut.u_tx.count == 4'd8)
                    tx_captured[tx_bit_idx] <= uart_XMIT_dataH;
                if (uut.u_tx.count == 4'd15)
                    tx_bit_idx <= tx_bit_idx + 1;
            end else begin
                if (uut.u_tx.ps == 2'd3)             // stop - reset for next byte
                    tx_bit_idx <= 3'd0;
            end
        end
    end

    // ──────────────────────────────────────────────
    //  RX CAPTURE
    //  rec_dataH is combinational in stop_r.
    //  Latch it at the b_clk edge when rec_readyH is high.
    // ──────────────────────────────────────────────
    reg [7:0] rx_captured;

    always @(posedge b_clk) begin
        if (rec_readyH)
            rx_captured <= rec_dataH;
    end

    // ──────────────────────────────────────────────
    //  TX SEND TASK
    //  Pulse xmitH for one b_clk, wait for xmit_doneH.
    // ──────────────────────────────────────────────
    task tx_send;
        input [7:0] data;
        begin
            xmit_dataH = data;
            @(posedge b_clk); #1;
            xmitH = 1'b1;
            @(posedge b_clk); #1;
            xmitH = 1'b0;
            @(posedge xmit_doneH);
            repeat(2) @(posedge b_clk);
        end
    endtask

    // ──────────────────────────────────────────────
    //  RX DRIVE TASK
    //  Manually bit-bang uart_REC_dataH.
    //  Each bit = 16 b_clk cycles (16x oversampling).
    // ──────────────────────────────────────────────
    task rx_drive;
        input [7:0] data;
        integer j;
        begin
            // Idle guard
            uart_REC_dataH = 1'b1;
            repeat(5) @(posedge b_clk);

            // START BIT
            uart_REC_dataH = 1'b0;
            repeat(16) @(posedge b_clk);

            // DATA BITS - LSB first
            for (j = 0; j < 8; j = j + 1) begin
                uart_REC_dataH = data[j];
                repeat(16) @(posedge b_clk);
            end

            // STOP BIT
            uart_REC_dataH = 1'b1;
            repeat(16) @(posedge b_clk);
        end
    endtask

    // ──────────────────────────────────────────────
    //  TX CHECK TASK
    // ──────────────────────────────────────────────
    task tx_check;
        input [7:0] expected;
        begin
            @(posedge b_clk); #1;
            if (tx_captured === expected)
                $display("TX PASS : expected=0x%02H  sent=0x%02H      time=%0t",
                          expected, tx_captured, $time);
            else
                $display("TX FAIL : expected=0x%02H  sent=0x%02H      time=%0t",
                          expected, tx_captured, $time);
        end
    endtask

    // ──────────────────────────────────────────────
    //  RX CHECK TASK
    // ──────────────────────────────────────────────
    task rx_check;
        input [7:0] expected;
        begin
            @(posedge b_clk); #1;
            if (rx_captured === expected)
                $display("RX PASS : expected=0x%02H  received=0x%02H  time=%0t",
                          expected, rx_captured, $time);
            else
                $display("RX FAIL : expected=0x%02H  received=0x%02H  time=%0t",
                          expected, rx_captured, $time);
        end
    endtask

    // ──────────────────────────────────────────────
    //  STIMULUS
    // ──────────────────────────────────────────────
    initial begin

//        $dumpfile("top_mod_tb.vcd");
//        $dumpvars(0, top_mod_tb);

        // INIT
        xmitH          = 1'b0;
        xmit_dataH     = 8'h00;
        uart_REC_dataH = 1'b1;   // idle high

        // ASSERT ACTIVE-LOW RESET
        sys_rst_l = 1'b0;
        repeat(10) @(posedge sys_clk);

        // RELEASE RESET
        sys_rst_l = 1'b1;
        repeat(10) @(posedge sys_clk);

        // ==================================================
        // TEST 1 : TX sends 0x55 | RX receives 0xA5
        //          Both run in parallel using fork..join
        // ==================================================
        $display("\n--- TEST 1 : TX=0x55  RX=0xA5 (parallel) ---");
        fork
            // TX thread
            begin
                tx_send(8'h55);
                tx_check(8'h55);
            end
            // RX thread
            begin
                rx_drive(8'h55);
                @(posedge rec_readyH);
                rx_check(8'h55);
            end
        join
        repeat(20) @(posedge b_clk);

        // ==================================================
        // TEST 2 : TX sends 0xFF | RX receives 0x00
        // ==================================================
        $display("\n--- TEST 2 : TX=0xFF  RX=0x00 (parallel) ---");
        fork
            begin
                tx_send(8'hFF);
                tx_check(8'hFF);
            end
            begin
                rx_drive(8'h00);
                @(posedge rec_readyH);
                rx_check(8'h00);
            end
        join
        repeat(20) @(posedge b_clk);

        // ==================================================
        // TEST 3 : TX sends 0xA5 | RX receives 0x55
        // ==================================================
        $display("\n--- TEST 3 : TX=0xA5  RX=0x55 (parallel) ---");
        fork
            begin
                tx_send(8'h55);
                tx_check(8'h55);
            end
            begin
                rx_drive(8'h55);
                @(posedge rec_readyH);
                rx_check(8'h55);
            end
        join
        repeat(20) @(posedge b_clk);

        // ==================================================
        // TEST 4 : TX only (RX idle)
        // ==================================================
        $display("\n--- TEST 4 : TX=0x12  RX=idle ---");
        uart_REC_dataH = 1'b1;
        tx_send(8'h12);
        tx_check(8'h12);
        repeat(20) @(posedge b_clk);

        // ==================================================
        // TEST 5 : RX only (TX idle)
        // ==================================================
        $display("\n--- TEST 5 : TX=idle  RX=0x34 ---");
        xmitH = 1'b0;
        rx_drive(8'h34);
        @(posedge rec_readyH);
        rx_check(8'h34);
        repeat(20) @(posedge b_clk);

        $display("\n=== SIMULATION DONE ===\n");
        $finish;
    end

    // ── Monitor ────────────────────────────────────
    initial begin
        $monitor("TIME=%0t | TX ps=%0d cnt=%0d i=%0d TX_LINE=%b DONE=%b | RX ps=%0d cnt=%0d bc=%0d RX_LINE=%b READY=%b",
                  $time,
                  uut.u_tx.ps,
                  uut.u_tx.count,
                  uut.u_tx.i,
                  uart_XMIT_dataH,
                  xmit_doneH,
                  uut.u_rx.ps,
                  uut.u_rx.count,
                  uut.u_rx.bit_count,
                  uart_REC_dataH,
                  rec_readyH);
    end

    // ── Watchdog ───────────────────────────────────
    initial begin
        #20_000_000;
        $display("[TIMEOUT] Simulation exceeded time limit.");
        $finish;
    end

endmodule
