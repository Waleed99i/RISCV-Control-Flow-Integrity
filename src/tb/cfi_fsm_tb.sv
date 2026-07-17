`timescale 1ns/1ps

module cfi_fsm_tb;

    logic clk;
    logic reset;
    logic [31:0] packet;

    cfi_fsm dut(
        .clk(clk),
        .reset(reset),
        .packet(packet)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // VCD Dump
    initial begin
        $dumpfile("build/cfi_fsm_tb.vcd");
        $dumpvars(0,cfi_fsm_tb);
    end

    // Task to send one packet
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

    initial begin

        
        // Reset
        

        packet = 32'd0;
        reset  = 1;

        repeat(2) @(posedge clk);

        reset = 0;

        $display("\n========== TEST START ==========\n");

        
        // Test 1 : SET
        

        $display("TEST1 : SET");

        send_packet(8'h01,24'hABCDEF);

        //$display("State = %0d",state);

        
        // Test 2 : JUMP
        

        $display("\nTEST2 : JUMP");

        send_packet(8'h02,24'h000000);

        //$display("State = %0d",state);

        
        // Test 3 : Correct LPAD
        

        $display("\nTEST3 : Correct LPAD");

        send_packet(8'h03,24'hABCDEF);

        //$display("State = %0d",state);

        
        // Test 4 : Wrong LPAD
        

        $display("\nTEST4 : Wrong LPAD");

        send_packet(8'h02,24'h0);

        send_packet(8'h03,24'h123456);

        //$display("State = %0d",state);

        
        // Test 5 : ERROR stays forever
        

        $display("\nTEST5 : ERROR forever");

        send_packet(8'h01,24'h999999);

        send_packet(8'h02,24'h0);

        send_packet(8'h03,24'h999999);

        //$display("State = %0d",state);

        
        // Finish
        

        #20;

        $display("\n========== TEST COMPLETE ==========\n");

        $finish;

    end

endmodule