`timescale 1ns/1ps

module cfi_fsm_v3_tb;

    logic clk, reset;
    logic [31:0] packet;

    localparam SET=8'h01, JUMP=8'h02, LPAD=8'h03;

    integer pass=0, fail=0;

    cfi_fsm dut(
      .clk(clk),
      .reset(reset),
      .packet(packet));

    initial begin 
        clk=0; 
        forever #5 clk=~clk; 
    end

    initial begin
      $dumpfile("build/cfi_fsm_v3_tb.vcd");
      $dumpvars(0,cfi_fsm_v3_tb);
    end

    task send_packet(
        input [7:0] cmd,
        input [23:0] data);
    begin
        packet={cmd,data};
        @(posedge clk); 
        #1;
        $display("Time=%0t CMD=%02h DATA=%06h STATE=%0d LABEL=%06h",
              $time,cmd,data,dut.state,dut.label);
    end
    endtask

    task check_state(
        input [1:0] exp,
        input [255:0] name);
    begin
        if(dut.state==exp) begin
            $display("[PASS] %0s",name); 
            pass++;
        end 
        else begin
            $display("[FAIL] %0s Exp=%0d Got=%0d",name,exp,dut.state); 
            fail++;
        end
    end
    endtask

    task check_label(
        input [23:0] exp,
        input [255:0] name);
    begin
        if(dut.label==exp) begin
            $display("[PASS] %0s",name); 
            pass++;
        end 
        else begin
            $display("[FAIL] %0s Exp=%06h Got=%06h",name,exp,dut.label); 
            fail++;
        end
    end
    endtask

    initial begin
    packet=0; 
    reset=1;
    repeat(2) @(posedge clk);
    reset=0;

    $display("\n==============================================");
    $display("      CFI FSM VERIFICATION SUITE");
    $display("==============================================\n");

    // Portion 1
    send_packet(SET,24'hABCDEF);
    check_state(dut.IDLE,"SET keeps IDLE");
    check_label(24'hABCDEF,"Label stored");

    // Portion 2
    send_packet(JUMP,0);
    check_state(dut.CHECK,"JUMP -> CHECK");

    // Portion 3
    send_packet(LPAD,24'hABCDEF);
    check_state(dut.IDLE,"Authorized LPAD");

    // Portion 4
    send_packet(SET,24'h555555);
    check_label(24'h555555,"Label updated #1");
    send_packet(JUMP,0);
    check_state(dut.CHECK,"CHECK entered");
    send_packet(LPAD,24'h555555);
    check_state(dut.IDLE,"Transaction #2");

    // Portion 5
    send_packet(SET,24'hCAFEBE);
    check_label(24'hCAFEBE,"Label updated #2");
    send_packet(JUMP,0);
    send_packet(LPAD,24'hCAFEBE);
    check_state(dut.IDLE,"Transaction #3");

    // Portion 6
    send_packet(SET,24'h111111);
    check_label(24'h111111,"Label updated #3");
    send_packet(JUMP,0);
    send_packet(LPAD,24'h123456);
    check_state(dut.ERROR,"Unauthorized LPAD");

    // Sticky error
    send_packet(SET,24'h999999);
    check_state(dut.ERROR,"ERROR ignores SET");
    send_packet(JUMP,0);
    check_state(dut.ERROR,"ERROR ignores JUMP");
    send_packet(LPAD,24'h999999);
    check_state(dut.ERROR,"ERROR ignores LPAD");
    send_packet(8'hFF,24'hAAAAAA);
    check_state(dut.ERROR,"Illegal command");
    send_packet(8'h77,24'hBBBBBB);
    check_state(dut.ERROR,"Random command");

    $display("\n==============================================");
    $display("Verification Summary");
    $display("==============================================");
    $display("Tests Passed : %0d",pass);
    $display("Tests Failed : %0d",fail);
    $display("\nState Coverage");
    $display("IDLE   : Covered");
    $display("CHECK  : Covered");
    $display("ERROR  : Covered");
    $display("\nCommand Coverage");
    $display("SET    : Covered");
    $display("JUMP   : Covered");
    $display("LPAD   : Covered");
    $display("Illegal: Covered");
    $display("\nScenario Coverage");
    $display("Label Storage          : Covered");
    $display("Multiple Label Updates : Covered");
    $display("Multiple Transactions  : Covered");
    $display("Authorized LPAD        : Covered");
    $display("Unauthorized LPAD      : Covered");
    $display("Sticky ERROR           : Covered");

    if(fail==0) 
        $display("\nOVERALL RESULT : PASS");
    else 
        $display("\nOVERALL RESULT : FAIL");
    #20 
    $finish;
    end

endmodule
