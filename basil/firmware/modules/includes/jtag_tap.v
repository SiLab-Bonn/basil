`ifndef JTAG_TAP
`define JTAG_TAP

`timescale 1ps / 1ps

/* JTAG TAP interface

   This module can be replaced with special JTAG TAP primitives on Xilinx and Altera FPGAs.
   Those primitives have similar interfaces; if you plan to modify this module's interface,
   make sure you do not make it incompatible with the other ones.

   About the clock: it would have been easier to use the system clock in this module,
   but the JTAG TAP interface should be able to work and do boundary scans
   even when the main system clock is disabled. Relying on the JTAG clock
   means that somewhere down the line crossing clock domains becomes necessary,
   which can slow JTAG firmware transfers down.

   About the delay in the is_tap_state_xxx signals:
   The is_tap_state_xxx are all delivered to the submodules delayed by 1 TCK posedge, see
   the comment below for more information. I am not sure whether these signals also
   get delayed when using the JTAG TAP primitives on Xilinx or Altera FPGAs.


   Author(s):
       Igor Mohor (igorm@opencores.org)
       Nathan Yawn (nathan.yawn@opencores.org)
       R. Diez (in 2012)

   NOTE: R. Diez has rewritten this module substantially and since then
         it has only been tested against the OR10 OpenRISC implementation.

   Copyright (C) 2000 - 2012 Authors

   This source file may be used and distributed without
   restriction provided that this copyright statement is not
   removed from the file and that any derivative work contains
   the original copyright notice and the associated disclaimer.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License version 3
   as published by the Free Software Foundation.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Lesser General Public License version 3 for more details.

   You should have received a copy of the GNU Lesser General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/////////////////////////////
//`include "simulator_features.v"
/////////////////////////////
`define UNIQUE
`define FINISH_WITH_ERROR_EXIT_CODE

// WARNING: __FILE__ and __LINE only available in SystemVerilog 2009 and later
// A Verilog only solution would be: define ASSERT_FALSE $display( "ERROR: Assertion failed in
// module %m." ); `FINISH_WITH_ERROR_EXIT_CODE
`define ASSERT_FALSE $display("ERROR: Assertion failed in module %m."); `FINISH_WITH_ERROR_EXIT_CODE

/////////////////////////////
//`include "tap_defines.v"
////////////////////////////
// This is similar to the IDCODE that the or1200 CPU uses,
// only the new part number (IQ) is the or1200's value + 100 (decimal).
// The or1200 uses 32'h149511c3.
`define OPENRISC_CPU_JTAG_IDCODE_VALUE 32'h149B51C3
// 0001             bits [31:28], version
// 0100100110110101 bits [27:12], part number (IQ), 01001001010101010001 + 100 (decimal)
// 00011100001      bits [11: 1], manufacturer id (flextronics)
// 1                bit 0, always "1" as required by the JTAG standard


// JTAG Instructions. The Instruction Register is 4 bits long at the moment,
// but 3 bits would do. However, this optimisation is probably not worth the trouble.
// EXTEST and SAMPLE_PRELOAD are not supported at the moment; IDCODE is supported.
`define JTAG_INSTRUCTION_EXTEST 4'b0000
`define JTAG_INSTRUCTION_SAMPLE_PRELOAD 4'b0001
`define JTAG_INSTRUCTION_IDCODE 4'b0010
// The following command is specific to OR10. Because the Xilinx TAP primitives have just 1 or 2
// user-defined
// JTAG instructions, all OR10 debug operations is performed with a single DEBUG instruction,
// which can be mapped to one of Xilinx' user-defined instructions when using that interface.
// If it weren't for this limitation, it would have been more comfortable to define
// several JTAG instructions for the different types of OR10 debug operations.
// DEBUG is specific to OR10; MBIST is not supported. BYPASS must be all 1's.
`define JTAG_INSTRUCTION_DEBUG 4'b1000
`define JTAG_INSTRUCTION_MBIST 4'b1001
`define JTAG_INSTRUCTION_BYPASS 4'b1111

module jtag_tap #(
    parameter TRACE_JTAG_DATA                 = 0,
    parameter TRACE_STATE_MACHINE_TRANSITIONS = 0
) (
    // JTAG pads
    input jtag_tms_i,  // If unconnected or not used, the JTAG standard requires a value of 1.
    input jtag_tck_i,
    // Test reset. Asynchronous, active at logic level 0. Therefore, if unconnected or not used,
    // apply a value of 1.
    input jtag_trstn_i,
    input jtag_tdi_i,  // If unconnected or not used, the JTAG standard requires a value of 1.
    output reg jtag_tdo_o,  // This pin should be tri-stated when not shifting data,
                            // but this module does not support an extra jtag_tdo_enable_o signal
                            // yet.

    // These previous state signals are delayed by one TCK clock cycle:
    // when a TAP submodule gets the next TCK rising edge, these signals
    // indicate what state the TAP was in at the last TCK rising edge.
    // One TCK posedge delay to reset the submodule is fine, as long as
    output reg is_tap_state_test_logic_reset_o,
    // the next TCK posedge comes soon enough.
    // One TCK posedge delay is fine, as bits are shifted on the next TCK posedge
    output reg is_tap_state_shift_dr_o,
    // after entering the Shift-DR state.
    // One TCK posedge delay is usually fine, the register update will happen a little later.
    output reg is_tap_state_update_dr_o,
    // This may be a problem if the next TCK posedge does not
    // come, or takes a long time to come.
    // One TCK posedge delay is usually fine, the register capture will happen a little later.
    output reg is_tap_state_capture_dr_o,
    // This may be a problem if the next TCK posedge does not
    // come, or takes a long time to come.


    // This signal is also delayed by one TCK clock cycle,
    // but that does not matter, as the current instruction changes only
    // in state Update-IR, and in that state all the is_tap_state_xxx signals are zero.
    // When any of the is_tap_state_xxx signals become active again,
    // this signal is already available.
    output reg is_tap_current_instruction_debug_o,

    // TDI signal from the debug submodule.
    //input      debug_tdo_i //TH
    output reg [31:0] debug_reg  //TH
);

    // Length of the Instruction register.
    localparam IR_LENGTH = 4;

    localparam TRACE_PREFIX = "JTAG TAP: ";


    // TAP State Machine, fully JTAG compliant.

    localparam STATE_TEST_LOGIC_RESET = 4'd0;  // The actual state values do not matter.
    localparam STATE_RUN_TEST_IDLE = 4'd1;
    localparam STATE_SELECT_DR_SCAN = 4'd2;
    localparam STATE_CAPTURE_DR = 4'd3;
    localparam STATE_SHIFT_DR = 4'd4;
    localparam STATE_EXIT1_DR = 4'd5;
    localparam STATE_PAUSE_DR = 4'd6;
    localparam STATE_EXIT2_DR = 4'd7;
    localparam STATE_UPDATE_DR = 4'd8;
    localparam STATE_SELECT_IR_SCAN = 4'd9;
    localparam STATE_CAPTURE_IR = 4'd10;
    // Once you enter this state, you'll shift at least 1 bit of information, as the TCK posedge
    // that exits the state does also transfer 1 bit.
    localparam STATE_SHIFT_IR = 4'd11;
    localparam STATE_EXIT1_IR = 4'd12;
    localparam STATE_PAUSE_IR = 4'd13;
    localparam STATE_EXIT2_IR = 4'd14;
    localparam STATE_UPDATE_IR = 4'd15;

    reg [3:0] current_state;  // Current state of the TAP controller.


    // The instruction register, when in state Capture-IR, gets a device-dependent status value.
    reg [IR_LENGTH-1:0] jtag_ir;
    // This is the content of jtag_ir register latched in state Update-IR.
    reg [IR_LENGTH-1:0] current_instruction;
    reg [31:0] idcode_reg;
    reg bypass_reg;


    function automatic [3:0] get_next_state;
        input reg [3:0] prev_state;
        begin
            case (prev_state)
                STATE_TEST_LOGIC_RESET: begin
                    if (jtag_tms_i) get_next_state = STATE_TEST_LOGIC_RESET;
                    else get_next_state = STATE_RUN_TEST_IDLE;
                end
                STATE_RUN_TEST_IDLE: begin
                    if (jtag_tms_i) get_next_state = STATE_SELECT_DR_SCAN;
                    else get_next_state = STATE_RUN_TEST_IDLE;
                end
                STATE_SELECT_DR_SCAN: begin
                    if (jtag_tms_i) get_next_state = STATE_SELECT_IR_SCAN;
                    else get_next_state = STATE_CAPTURE_DR;
                end
                STATE_CAPTURE_DR: begin
                    if (jtag_tms_i) get_next_state = STATE_EXIT1_DR;
                    else get_next_state = STATE_SHIFT_DR;
                end
                STATE_SHIFT_DR: begin
                    if (jtag_tms_i) get_next_state = STATE_EXIT1_DR;
                    else get_next_state = STATE_SHIFT_DR;
                end
                STATE_EXIT1_DR: begin
                    if (jtag_tms_i) get_next_state = STATE_UPDATE_DR;
                    else get_next_state = STATE_PAUSE_DR;
                end
                STATE_PAUSE_DR: begin
                    if (jtag_tms_i) get_next_state = STATE_EXIT2_DR;
                    else get_next_state = STATE_PAUSE_DR;
                end
                STATE_EXIT2_DR: begin
                    if (jtag_tms_i) get_next_state = STATE_UPDATE_DR;
                    else get_next_state = STATE_SHIFT_DR;
                end
                STATE_UPDATE_DR: begin
                    if (jtag_tms_i) get_next_state = STATE_SELECT_DR_SCAN;
                    else get_next_state = STATE_RUN_TEST_IDLE;
                end
                STATE_SELECT_IR_SCAN: begin
                    if (jtag_tms_i) get_next_state = STATE_TEST_LOGIC_RESET;
                    else get_next_state = STATE_CAPTURE_IR;
                end
                STATE_CAPTURE_IR: begin
                    if (jtag_tms_i) get_next_state = STATE_EXIT1_IR;
                    else get_next_state = STATE_SHIFT_IR;
                end
                STATE_SHIFT_IR: begin
                    if (jtag_tms_i) get_next_state = STATE_EXIT1_IR;
                    else get_next_state = STATE_SHIFT_IR;
                end
                STATE_EXIT1_IR: begin
                    if (jtag_tms_i) get_next_state = STATE_UPDATE_IR;
                    else get_next_state = STATE_PAUSE_IR;
                end
                STATE_PAUSE_IR: begin
                    if (jtag_tms_i) get_next_state = STATE_EXIT2_IR;
                    else get_next_state = STATE_PAUSE_IR;
                end
                STATE_EXIT2_IR: begin
                    if (jtag_tms_i) get_next_state = STATE_UPDATE_IR;
                    else get_next_state = STATE_SHIFT_IR;
                end
                STATE_UPDATE_IR: begin
                    if (jtag_tms_i) get_next_state = STATE_SELECT_DR_SCAN;
                    else get_next_state = STATE_RUN_TEST_IDLE;
                end
                default: begin
                end
            endcase
        end
    endfunction


    // Verilog-2005 functions use static lifetime by default.
    // verilog_lint: waive explicit-function-lifetime
    function [16*8-1:0] get_state_name;
        input [3:0] state;
        begin
            case (state)
                STATE_TEST_LOGIC_RESET: get_state_name = "Test Logic Reset";
                STATE_RUN_TEST_IDLE:    get_state_name = "Run-Test / Idle";
                STATE_SELECT_DR_SCAN:   get_state_name = "Select-DR";
                STATE_CAPTURE_DR:       get_state_name = "Capture-DR";
                STATE_SHIFT_DR:         get_state_name = "Shift-DR";
                STATE_EXIT1_DR:         get_state_name = "Exit1-DR";
                STATE_PAUSE_DR:         get_state_name = "Pause-DR";
                STATE_EXIT2_DR:         get_state_name = "Exit2-DR";
                STATE_UPDATE_DR:        get_state_name = "Update-DR";
                STATE_SELECT_IR_SCAN:   get_state_name = "Select-IR";
                STATE_CAPTURE_IR:       get_state_name = "Capture-IR";
                STATE_SHIFT_IR:         get_state_name = "Shift-IR";
                STATE_EXIT1_IR:         get_state_name = "Exit1-IR";
                STATE_PAUSE_IR:         get_state_name = "Pause-IR";
                STATE_EXIT2_IR:         get_state_name = "Exit2-IR";
                STATE_UPDATE_IR:        get_state_name = "Update-IR";
                default: begin
                end
            endcase
        end
    endfunction


    // Verilog-2005 functions use static lifetime by default.
    // verilog_lint: waive explicit-function-lifetime
    function [14*8-1:0] get_instruction_name;
        input [IR_LENGTH-1:0] state;
        begin
            case (state)
                `JTAG_INSTRUCTION_EXTEST:         get_instruction_name = "EXTEST";
                `JTAG_INSTRUCTION_SAMPLE_PRELOAD: get_instruction_name = "SAMPLE/PRELOAD";
                `JTAG_INSTRUCTION_IDCODE:         get_instruction_name = "IDCODE";
                `JTAG_INSTRUCTION_DEBUG:          get_instruction_name = "DEBUG";
                `JTAG_INSTRUCTION_MBIST:          get_instruction_name = "MBIST";
                `JTAG_INSTRUCTION_BYPASS:         get_instruction_name = "BYPASS";
                default:                          get_instruction_name = "<unknown>";
            endcase
        end
    endfunction


    task automatic reset_initial;
        begin
            // See the comments in sibling task 'reset_sync' for more information.
            current_state                      = STATE_TEST_LOGIC_RESET;
            current_instruction                = `JTAG_INSTRUCTION_IDCODE;
            jtag_ir                            = {IR_LENGTH{1'bx}};
            bypass_reg                         = 1'bx;
            idcode_reg                         = {32{1'bx}};
            debug_reg                          = {32{1'b0}};  //TH
            is_tap_current_instruction_debug_o = 0;
            is_tap_state_test_logic_reset_o    = 0;
            is_tap_state_shift_dr_o            = 0;
            is_tap_state_update_dr_o           = 0;
            is_tap_state_capture_dr_o          = 0;
        end
    endtask

    task automatic reset_sync;
        begin
            // If you change this task, please update sibling task 'reset_initial' too.

            current_state                      <= STATE_TEST_LOGIC_RESET;

            // As this JTAG TAP does support the IDCODE instruction, that's the one
            // selected upon reset. Otherwise, we should select the BYPASS instruction.
            current_instruction                <= `JTAG_INSTRUCTION_IDCODE;

            // We do not need to initialise the other registers, as the TAP state machine
            // always goes through states Capture-IR or Capture-DR, which initialises them
            // when they are needed.
            jtag_ir                            <= {IR_LENGTH{1'bx}};
            bypass_reg                         <= 1'bx;
            idcode_reg                         <= {32{1'bx}};
            debug_reg                          <= {32{1'b0}};

            is_tap_current_instruction_debug_o <= 0;

            is_tap_state_test_logic_reset_o    <= 0;
            is_tap_state_shift_dr_o            <= 0;
            is_tap_state_update_dr_o           <= 0;
            is_tap_state_capture_dr_o          <= 0;
        end
    endtask


    // We need this temporary variable because of a limitation in Verilator.
    reg [16*8-1:0] initial_state_name;

    initial begin
        // This is so that, in FPGAs, there is no need to trigger the reset signal at the beginning,
        // it can then be hard-wired to '1' and optimised away by the synthesiser.
        reset_initial;

        if (TRACE_STATE_MACHINE_TRANSITIONS) begin
            initial_state_name = get_state_name(current_state);
            $display("%sStarting up in initial state '%0s'.", TRACE_PREFIX, initial_state_name);
        end
    end


    // Verilog-2005 tasks use static lifetime by default.
    // verilog_lint: waive explicit-task-lifetime
    task do_capture_dr;
        reg [14*8-1:0] instruction_name;
        begin
            instruction_name = get_instruction_name(current_instruction);

            case (current_instruction)
                `JTAG_INSTRUCTION_IDCODE: idcode_reg <= `OPENRISC_CPU_JTAG_IDCODE_VALUE;
                `JTAG_INSTRUCTION_BYPASS:
                bypass_reg <= 0;  // Must be 0 according to the JTAG specification.
                `JTAG_INSTRUCTION_DEBUG: begin
                    // Nothing to do here, a submodule will do all the processing for this command.
                end
                `JTAG_INSTRUCTION_EXTEST,
             `JTAG_INSTRUCTION_SAMPLE_PRELOAD,
             `JTAG_INSTRUCTION_MBIST:
               begin
                    $display("%sInstruction %0s is not supported or has not been fully tested yet.",
                             TRACE_PREFIX, instruction_name);
                    `FINISH_WITH_ERROR_EXIT_CODE;
                end
                default: begin
                    `ASSERT_FALSE;
                    // For all unknown JTAG instructions, the standard requires the bypass register.
                    bypass_reg <= 0;
                end
            endcase
        end
    endtask


    // Verilog-2005 tasks use static lifetime by default.
    // verilog_lint: waive explicit-task-lifetime
    task do_shift_dr;
        begin
            case (current_instruction)
                `JTAG_INSTRUCTION_IDCODE:
                idcode_reg <= {
                    jtag_tdi_i, idcode_reg[31:1]
                };  // Note that this overwrites the IDCODE register. It shouldn't really matter.

                `JTAG_INSTRUCTION_BYPASS: bypass_reg <= jtag_tdi_i;

                `JTAG_INSTRUCTION_DEBUG: begin
                    // Nothing to do here, a submodule will do all the processing for this command.
                    debug_reg <= {jtag_tdi_i, debug_reg[31:1]};  //TH
                end

                default: begin
                    // Note that task 'do_capture_dr' already catches all default cases.
                    `ASSERT_FALSE;
                    // For all unknown JTAG instructions, the standard requires the bypass register.
                    bypass_reg <= jtag_tdi_i;
                end
            endcase
        end
    endtask


    task automatic tck_posedge;
        reg [14*8-1:0] instruction_name;
        begin
            case (current_state)
                STATE_TEST_LOGIC_RESET: reset_sync;

                STATE_CAPTURE_IR:
                jtag_ir <= {
                    2'b01,  // Some fixed status value to help debugging this module,
                            // we don't actually have any status to report.

                    2'b01
                };  // Bits [1:0] must be "01" according to the JTAG specification,
                    // which helps tell whether a device in the JTAG chain supports the IDCODE
                    // instruction
                    // or not (in which case it would be in BYPASS mode, and its first bit would
                    // then be 0).

                STATE_UPDATE_IR: begin
                    if (TRACE_STATE_MACHINE_TRANSITIONS) begin
                        instruction_name = get_instruction_name(jtag_ir);
                        $display("%sCurrent instruction set to %0s.", TRACE_PREFIX,
                                 instruction_name);
                    end

                    current_instruction                <= jtag_ir;

                    is_tap_current_instruction_debug_o <= 0;

                    case (jtag_ir)
                        `JTAG_INSTRUCTION_DEBUG: is_tap_current_instruction_debug_o <= 1;
                        default: begin
                            // Nothing to do here.
                        end
                    endcase
                end

                STATE_SHIFT_IR: jtag_ir <= {jtag_tdi_i, jtag_ir[IR_LENGTH-1:1]};

                STATE_CAPTURE_DR: do_capture_dr;

                STATE_SHIFT_DR: do_shift_dr;

                default: begin
                    // Nothing to do here.
                end
            endcase
        end
    endtask


    task automatic switch_to_next_state;
        reg [3:0] next_state;
        reg [16*8-1:0] prev_state_name;
        reg [16*8-1:0] next_state_name;
        begin
            next_state = get_next_state(current_state);

            if (TRACE_JTAG_DATA || TRACE_STATE_MACHINE_TRANSITIONS) begin
                prev_state_name = get_state_name(current_state);

                if (next_state == current_state) begin
                    if (TRACE_JTAG_DATA)
                        $display(
                            "%sTCK posedge, TMS=%0d, TDI=%0d while in state '%0s'.",
                            TRACE_PREFIX,
                            jtag_tms_i,
                            jtag_tdi_i,
                            prev_state_name
                        );
                end else begin
                    next_state_name = get_state_name(next_state);

                    if (TRACE_JTAG_DATA)
                        $display(
                            "%sTCK posedge, TMS=%0d, TDI=%0d, changing state from '%0s' to '%0s'.",
                            TRACE_PREFIX,
                            jtag_tms_i,
                            jtag_tdi_i,
                            prev_state_name,
                            next_state_name
                        );

                    if (TRACE_STATE_MACHINE_TRANSITIONS)
                        $display(
                            "%sChanging state from '%0s' to '%0s'.",
                            TRACE_PREFIX,
                            prev_state_name,
                            next_state_name
                        );
                end
            end

            current_state                   <= next_state;

            is_tap_state_test_logic_reset_o <= 0;
            is_tap_state_shift_dr_o         <= 0;
            is_tap_state_update_dr_o        <= 0;
            is_tap_state_capture_dr_o       <= 0;

            case (next_state)
                STATE_TEST_LOGIC_RESET: is_tap_state_test_logic_reset_o <= 1;
                STATE_SHIFT_DR:         is_tap_state_shift_dr_o <= 1;
                STATE_UPDATE_DR:        is_tap_state_update_dr_o <= 1;
                STATE_CAPTURE_DR:       is_tap_state_capture_dr_o <= 1;
                default: begin
                    // Nothing to do here.
                end
            endcase
        end
    endtask


    task automatic tck_negedge;
        reg [16*8-1:0] state_name;
        begin
            if (TRACE_JTAG_DATA) begin
                state_name = get_state_name(current_state);
                $display("%sTCK negedge, TMS=%0d, TDI=%0d while in state '%0s'.", TRACE_PREFIX,
                         jtag_tms_i, jtag_tdi_i, state_name);
            end

            // According to the JTAG specification TDO changes state at the negative edge of TCK.
            // This is from the documentation about Xilinx BSCAN_SPARTAN6 (which allows access to
            // the FPGA's JTAG TAP):
            //   TDO input driven from the user fabric logic. This signal is
            //   internally sampled on the falling edge before being driven out
            //   to the FPGA TDO pin.

            if (current_state == STATE_SHIFT_IR) jtag_tdo_o <= jtag_ir[0];
            else begin
                case (current_instruction)
                    `JTAG_INSTRUCTION_IDCODE: jtag_tdo_o <= idcode_reg[0];
                    `JTAG_INSTRUCTION_DEBUG: jtag_tdo_o <= debug_reg[0];  //debug_tdo_i; TH
                    `JTAG_INSTRUCTION_SAMPLE_PRELOAD:
                    jtag_tdo_o <= 0;  // Boundary scan not supported.
                    `JTAG_INSTRUCTION_EXTEST: jtag_tdo_o <= 0;  // Boundary scan not supported.
                    `JTAG_INSTRUCTION_MBIST: jtag_tdo_o <= 0;  // MBIST not supported.
                    default: jtag_tdo_o <= bypass_reg;
                endcase
            end
        end
    endtask


    always @(posedge jtag_tck_i or negedge jtag_trstn_i) begin
        // These 2 conditions must be combined in a single always block,
        // otherwise Verilator complains that current_state has 2 drivers,
        // as the reset is asynchronous.

        if (jtag_trstn_i == 0) begin
            if (TRACE_STATE_MACHINE_TRANSITIONS)
                $display("%sAsync reset signal TRST asserted (the value is now 0).", TRACE_PREFIX);

            reset_sync;
        end else begin
            tck_posedge;
            switch_to_next_state;
        end
    end

    always @(negedge jtag_tck_i) begin
        tck_negedge;
    end

    always @(posedge jtag_trstn_i) begin
        if (TRACE_STATE_MACHINE_TRANSITIONS)
            $display("%sAsync reset signal TRST deasserted (the value is now 1).", TRACE_PREFIX);
    end

endmodule

`endif
