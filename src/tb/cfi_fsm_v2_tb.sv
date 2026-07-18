`timescale 1ns/1ps

module cfi_fsm_v2_tb;
    logic clk;
    logic reset;
    logic [31:0] packet;
    cfi_fsm dut(
        .clk(clk),
        .reset(reset),
        .packet(packet)
    );
    localparam SET  = 8'h01;
    localparam JUMP = 8'h02;
    localparam LPAD = 8'h03;
    // Counters
    integer tests_passed = 0;
    integer tests_failed = 0;
    //clk
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    // VCD
    initial begin
        $dumpfile("build/cfi_fsm_v2_tb.vcd");
        $dumpvars(0,cfi_fsm_v2_tb);
    end
    // Packet Task
    task send_packet(
        input [7:0] cmd,
        input [23:0] data
    );
    begin
        packet = {cmd,data};
        @(posedge clk);
        #1;
    end
    endtask
    // State Checker
    task check_state(
        input [1:0] expected,
        input [255:0] test_name
    );
    begin
        if(dut.state == expected) begin
            $display("[PASS] %s", test_name);
            tests_passed++;
        end
        else begin
            $display("[FAIL] %s", test_name);
            $display("       Expected = %0d", expected);
            $display("       Got      = %0d", dut.state);
            tests_failed++;
        end
    end
    endtask

    // Tests
    initial begin
        packet = 0;
        reset  = 1;
        repeat(2) @(posedge clk);
        reset = 0;
        $display("\n========================================");
        $display("     CFI FSM VERIFICATION START");
        $display("========================================\n");

        // Test 1
        send_packet(SET,24'hABCDEF);
        check_state(dut.IDLE,
            "SET stores label and remains in IDLE");
        
        // Test 2
        send_packet(JUMP,24'd0);
        check_state(dut.CHECK,
            "JUMP moves IDLE -> CHECK");

        // Test 3
        send_packet(LPAD,24'hABCDEF);
        check_state(dut.IDLE,
            "Matching LPAD returns to IDLE");

        // Test 4
        send_packet(JUMP,24'd0);
        check_state(dut.CHECK,
            "Second JUMP enters CHECK");
        send_packet(LPAD,24'h123456);
        check_state(dut.ERROR,
            "Wrong LPAD enters ERROR");
        
        // Test 5
        send_packet(SET,24'h999999);
        check_state(dut.ERROR,
            "ERROR ignores SET");
        
        // Test 6
        send_packet(JUMP,24'd0);
        check_state(dut.ERROR,
            "ERROR ignores JUMP");

        // Test 7
        send_packet(LPAD,24'h999999);
        check_state(dut.ERROR,
            "ERROR ignores LPAD");
        
        // Summary
        $display("\n========================================");
        $display("Verification Summary");
        $display("----------------------------------------");
        $display("Tests Passed : %0d",tests_passed);
        $display("Tests Failed : %0d",tests_failed);
        $display("========================================");

        if(tests_failed == 0)
            $display("\n********** ALL TESTS PASSED **********\n");
        else
            $display("\n********** TEST FAILED **********\n");

        #20;
        $finish;
    end
endmodule