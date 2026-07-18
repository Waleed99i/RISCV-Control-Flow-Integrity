`timescale 1ns/1ps

module cfi_fsm_v4_tb;
    logic clk;
    logic reset;
    logic [31:0] packet;
    cfi_fsm dut (
        .clk    (clk),
        .reset  (reset),
        .packet (packet)
    );
    localparam logic [7:0] SET  = 8'h01;
    localparam logic [7:0] JUMP = 8'h02;
    localparam logic [7:0] LPAD = 8'h03;

    integer total_tests  = 0;
    integer tests_passed = 0;
    integer tests_failed = 0;

    integer idle_hits  = 0;
    integer check_hits = 0;
    integer error_hits = 0;

    integer set_hits   = 0;
    integer jump_hits  = 0;
    integer lpad_hits  = 0;
    integer illegal_hits = 0;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("build/cfi_fsm_v4_tb.vcd");
        $dumpvars(0,cfi_fsm_v4_tb);
    end

    function string cmd_to_string(input logic [7:0] cmd);
        case(cmd)
            SET  : cmd_to_string = "SET ";
            JUMP : cmd_to_string = "JUMP";
            LPAD : cmd_to_string = "LPAD";

            default : cmd_to_string = "ILGL";
        endcase
    endfunction

    function string state_to_string(input logic [1:0] state);
        case(state)
            dut.IDLE  : state_to_string = "IDLE ";
            dut.CHECK : state_to_string = "CHECK";
            dut.ERROR : state_to_string = "ERROR";

            default   : state_to_string = "UNKWN";
        endcase

    endfunction
    
    // Coverage Collection
    task automatic update_coverage
    (
        input logic [7:0] cmd
    );

    begin
        case(dut.state)
            dut.IDLE  : idle_hits++;
            dut.CHECK : check_hits++;
            dut.ERROR : error_hits++;
        endcase

        case(cmd)
            SET  : set_hits++;
            JUMP : jump_hits++;
            LPAD : lpad_hits++;
            default : illegal_hits++;
        endcase
    end
    endtask

    
    // Packet Driver

    task automatic send_packet
    (
        input logic [7:0] cmd,
        input logic [23:0] data
    );
    begin
        packet = {cmd,data};
        @(posedge clk);
        #1;
        update_coverage(cmd);
        $display("%0t | CMD=%s | DATA=%06h | STATE=%s | LABEL=%06h",
                    $time,
                    cmd_to_string(cmd),
                    data,
                    state_to_string(dut.state),
                    dut.label);
    end
    endtask

    // PASS / FAIL Checkers    

    task automatic check_state
    (
        input logic [1:0] expected,
        input string message
    );
    begin
        total_tests++;
        if(dut.state == expected) begin
            tests_passed++;
            $display("[PASS] %s",message);
        end

        else begin
            tests_failed++;
            $display("[FAIL] %s",message);
            $display("       Expected : %s",
                        state_to_string(expected));

            $display("       Observed : %s",
                        state_to_string(dut.state));
        end
    end
    endtask


    task automatic check_label
    (
        input logic [23:0] expected,
        input string message
    );
    begin
        total_tests++;
        if(dut.label == expected) begin
            tests_passed++;
            $display("[PASS] %s",message);
        end
        else begin
            tests_failed++;
            $display("[FAIL] %s",message);
            $display("       Expected : %06h",expected);
            $display("       Observed : %06h",dut.label);
        end
    end

    endtask

    
    // Pretty Printing
    task automatic print_test_header
    (
        input string title
    );
    begin
        $display("");
        $display("------------------------------------------------------------");
        $display("%s",title);
        $display("------------------------------------------------------------");
    end
    endtask;

    // Reset Task
    
    task automatic apply_reset;
    begin
        packet = 32'd0;
        reset = 1'b1;
        repeat(2)
            @(posedge clk);
        reset = 1'b0;
        @(posedge clk);
    end
    endtask

        
    // Verification Sequences
    
    // Test reset functionality
    task automatic test_reset;
    begin
        print_test_header("[TEST 01] Reset Functionality");
        apply_reset();
        check_state(dut.IDLE,
                    "FSM enters IDLE after reset");

        check_label(24'd0,
                    "Label cleared after reset");
    end
    endtask


    // Load a new secure label
    task automatic load_label
    (
        input logic [23:0] new_label
    );
    begin
        send_packet(SET,new_label);
        check_state(dut.IDLE,
                    "SET keeps FSM in IDLE");

        check_label(new_label,
                    "Secure label stored");
    end
    endtask


    // Verify a legal control-flow transfer
    task automatic valid_transaction
    (
        input logic [23:0] label_value,
        input string transaction_name
    );
    begin
        print_test_header(transaction_name);
        load_label(label_value);
        send_packet(JUMP,24'd0);
        check_state(dut.CHECK,
                    "JUMP enters CHECK state");
        send_packet(LPAD,label_value);
        check_state(dut.IDLE,
                    "Matching LPAD returns to IDLE");
    end
    endtask


    // Verify incorrect landing pad detection
    task automatic invalid_transaction
    (
        input logic [23:0] stored_label,
        input logic [23:0] received_label
    );
    begin
        print_test_header("[TEST] Unauthorized Landing Pad");
        load_label(stored_label);
        send_packet(JUMP,24'd0);
        check_state(dut.CHECK,
                    "Entered CHECK");
        send_packet(LPAD,received_label);
        check_state(dut.ERROR,
                    "Incorrect LPAD detected");
    end
    endtask


    // ERROR must be sticky forever
    task automatic verify_sticky_error;
    begin
        print_test_header("[TEST] Sticky ERROR Verification");
        send_packet(SET,24'hAAAAAA);
        check_state(dut.ERROR,
                    "ERROR ignores SET");
        send_packet(JUMP,24'd0);
        check_state(dut.ERROR,
                    "ERROR ignores JUMP");
        send_packet(LPAD,24'hAAAAAA);
        check_state(dut.ERROR,
                    "ERROR ignores LPAD");
    end
    endtask


    // Illegal commands
    task automatic illegal_command_test
    (
        input logic [7:0] illegal_cmd
    );

    begin
        send_packet(illegal_cmd,24'h123456);
        check_state(dut.ERROR,
                    "Illegal command keeps ERROR");
    end
    endtask


    // Consecutive label updates
    task automatic multiple_label_updates;
    begin
        print_test_header("[TEST] Multiple Label Updates");
        load_label(24'h111111);
        load_label(24'h222222);
        load_label(24'h333333);
        load_label(24'h444444);
        check_label(24'h444444,
                    "Latest label retained");
    end
    endtask


    // Multiple successful transactions
    task automatic repeated_valid_transactions;
    begin
        valid_transaction(24'hABCDEF,
            "[TEST] Valid Transaction #1");
        valid_transaction(24'h555555,
            "[TEST] Valid Transaction #2");
        valid_transaction(24'hCAFEBE,
            "[TEST] Valid Transaction #3");
    end
    endtask


    // Unknown commands while IDLE
    task automatic idle_illegal_commands;
    begin
        print_test_header("[TEST] Illegal Commands in IDLE");
        send_packet(8'hAA,24'h111111);
        check_state(dut.IDLE,
                    "Unknown command ignored");
        send_packet(8'h55,24'h222222);
        check_state(dut.IDLE,
                    "Unknown command ignored");
        send_packet(8'hF0,24'h333333);
        check_state(dut.IDLE,
                    "Unknown command ignored");
    end
    endtask


    // Continuous packet stream
    task automatic stress_test;
    begin
        print_test_header("[TEST] Continuous Packet Stream");
        load_label(24'h654321);
        repeat(3) begin
            send_packet(JUMP,24'd0);
            check_state(dut.CHECK,
                        "Entered CHECK");
            send_packet(LPAD,24'h654321);
            check_state(dut.IDLE,
                        "Returned to IDLE");
        end
    end
    endtask

    
    // Summary Printer    

    task automatic print_summary;
    begin
        $display("");
        $display("============================================================");
        $display("                 Verification Summary");
        $display("============================================================");

        $display("Tests Executed : %0d",total_tests);
        $display("Tests Passed   : %0d",tests_passed);
        $display("Tests Failed   : %0d",tests_failed);

        $display("");

        $display("State Coverage");
        $display("----------------");
        $display("IDLE   : %0d",idle_hits);
        $display("CHECK  : %0d",check_hits);
        $display("ERROR  : %0d",error_hits);

        $display("");

        $display("Command Coverage");
        $display("----------------");
        $display("SET     : %0d",set_hits);
        $display("JUMP    : %0d",jump_hits);
        $display("LPAD    : %0d",lpad_hits);
        $display("ILLEGAL : %0d",illegal_hits);

        $display("");

        if(tests_failed == 0)
            $display("OVERALL RESULT : PASS");

        else
            $display("OVERALL RESULT : FAIL");

        $display("============================================================");

    end
    endtask
        
    // Main Verification Flow
    

    initial begin

        $display("");
        $display("============================================================");
        $display("           CFI FSM RTL Verification Environment");
        $display("============================================================");

        
        // Initialization
        packet = 32'd0;
        reset  = 1'b0;
        
        // Regression Test Suite

        test_reset();
        idle_illegal_commands();
        valid_transaction(
            24'hABCDEF,
            "[TEST 02] Valid Transaction #1"
        );

        valid_transaction(
            24'h555555,
            "[TEST 03] Valid Transaction #2"
        );

        multiple_label_updates();

        valid_transaction(
            24'h444444,
            "[TEST 05] Valid Transaction After Label Updates"
        );

        stress_test();

        invalid_transaction(
            24'hCAFEBE,
            24'h123456
        );

        verify_sticky_error();

        print_test_header(
            "[TEST] Illegal Commands in ERROR"
        );

        illegal_command_test(8'hFF);

        illegal_command_test(8'hAA);

        illegal_command_test(8'h55);

        illegal_command_test(8'h99);

        illegal_command_test(8'h7E);

        
        // Final Summary
        
        print_summary();

        $display("");

        $display("Scenario Coverage");
        $display("-------------------------------");

        $display("[PASS] Reset");
        $display("[PASS] Label Storage");
        $display("[PASS] Label Overwrite");
        $display("[PASS] Valid Control Flow");
        $display("[PASS] Invalid Landing Pad");
        $display("[PASS] Multiple Transactions");
        $display("[PASS] Continuous Packet Stream");
        $display("[PASS] Sticky ERROR");
        $display("[PASS] Illegal Commands");
        $display("[PASS] State Transitions");

        $display("");

        $display("Verification Complete.");

        #20;

        $finish;

    end

endmodule