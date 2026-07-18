module cfi_fsm_modified (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] packet
);
    logic [23:0] label;

    logic [7:0]  cmd;
    logic [23:0] data;

    assign cmd  = packet[31:24];
    assign data = packet[23:0];

    localparam logic [7:0] SET  = 8'h01;
    localparam logic [7:0] JUMP = 8'h02;
    localparam logic [7:0] LPAD = 8'h03;

    typedef enum logic [1:0] {
        IDLE,
        CHECK,
        ERROR
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= IDLE;
            label <= 24'd0;
        end
        else begin
            state <= next_state;
            if(state == IDLE && cmd == SET)
                label <= data;
        end
    end

    always_comb begin
        next_state = state;
        case(state)
            IDLE : begin
                label = data;
                if(cmd == JUMP)
                    next_state = CHECK;
                else
                    next_state = IDLE;
            end

            CHECK : begin
                if(cmd == LPAD && data == label)
                    next_state = IDLE;
                else
                    next_state = ERROR;
            end

            ERROR : begin
                next_state = ERROR;
            end

        endcase

    end

endmodule