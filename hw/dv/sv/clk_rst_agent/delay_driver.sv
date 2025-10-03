// Copyright zeroRISC Inc.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class delay_driver extends dv_rst_safe_base_driver #(.ITEM_T(clk_rst_item),
                                                     .CFG_T (clk_rst_agent_cfg));
  `uvm_component_utils(delay_driver)


  // The base class provides the following handles for use:
  // clk_rst_agent_cfg: cfg

  `uvm_component_new

  virtual task run_phase(uvm_phase phase);
    // This driver is reset safe. When reset is asserted all delay transactions in flight are
    // immediately terminated by the parent class.
    super.run_phase(phase);
  endtask


  // reset signals
  virtual function void reset_interface_and_driver();
    // Nothing to do here. Have this empty function as it is necessary to overcome the fatal in the
    // parent class.
  endfunction

  // Drive outputs based on inputs
  virtual task get_and_drive();
    clk_rst_item  item;

    forever begin
      // Get the next data item from sequencer
      get_next_item (item);

      if (item.item_type == clk_rst_item::DELAY) begin
        cfg.reset_domain.clk_rst_vif.wait_clks(item.delay_time_steps);
      end else begin
        `uvm_fatal (`gfn, {"Unsupported item.type: ", item.item_type.name()})
      end

      item_done();
    end // forever
  endtask

endclass
