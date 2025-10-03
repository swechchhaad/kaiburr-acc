// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// 'reset_seq' is an interface sequence that work on the clock reset sequencer connected to the clock
// reset interface.
//
// The primary function of the reset sequence is to trigger 'reset' on the reset domain associated
// to the clock reset agent.
//
// To use this sequence in a higher level virtual sequence
// - Create an instance of the 'reset_seq'
// - Start the execution of the sequence : reset_seq_inst.start(clk_rst_sequencer)


class reset_seq extends dv_base_seq #(
    .REQ         (clk_rst_item),
    .CFG_T       (clk_rst_agent_cfg),
    .SEQUENCER_T (clk_rst_sequencer)
  );
  `uvm_object_utils(reset_seq)

  `uvm_object_new

  virtual task body();
    clk_rst_item  item;

    `uvm_info (get_name(), "Starting reset_sequence::body()", UVM_LOW)

    item           = clk_rst_item::type_id::create("reset_seq:item");
    item.item_type = clk_rst_item::APPLY_RESET;
    `DV_CHECK_RANDOMIZE_FATAL(item)

    start_item(item);
    finish_item(item);
  endtask

endclass
