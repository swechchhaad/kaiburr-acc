// Copyright zeroRISC Inc.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class dv_callback #(type ITEM_T=uvm_sequence_item) extends uvm_callback;

   virtual function void connect_to_callback();
     `uvm_fatal ("DV_BASE_CALLBACK", {"dv_callback cannont be used in the default mode.",
                                      "Please use the macro \`dv_callback_imp_decl"});
   endfunction

   virtual function void indicated(ITEM_T trans);
   endfunction
endclass

// The macro 'dv_callback_imp_decl' is provided to simplify the connections between the source of
// data (typically the monitor) and the consumer of data. (i.e Scoreboards, Sequences). In UVM, data
// flow into scoreboards is usually achieved via analysis ports connected through the hierarchy from
// the monitor to the scoreboard, however connections in sequence have a lot more challenges and
// limit the ability of sequences to be reactive.
//
// Using callbacks removes the restriction on any sequence to get feedback from the monitors and be
// reactive to what happening in the RTL.

// All monitors are equipped to support callbacks. When the monitor calls the 'notify()' method with
// the item that it want to broadcast it simultaneously send it on the analysis ports that are
// connected to the scoreboard and also to the subscribers registered using the callback macro.
//
// To connect the sequence to a specific monitor we need the following elements
// NAME_CB_OBJ  : Name for the callback object that will be used for instantiating in the subscriber
// AGENT_NAME   : Name of the agent in the UVM hierarchy that the subscriber wants to connect to
// ITEM_T       : Type of the Item that will be transmitted by the monitor. This  is what the
//                subscriber will receive from the monitor
// RECEIVER_T   : Subscriber's type
// RECEIVER_FUNC: The method (function) defined in the subscriber that will accept ITEM_T argument
//                to process any actions based on data it receives.

`define dv_callback_imp_decl(NAME_CB_OBJ, AGENT_NAME, ITEM_T, RECEIVER_T, RECEIVER_FUNC)       \
`ifndef RECEIVER_T``_DEF                                                                       \
`define RECEIVER_T``_DEF                                                                       \
typedef class RECEIVER_T;                                                                      \
`endif                                                                                         \
                                                                                               \
class NAME_CB_OBJ extends dv_callback #(ITEM_T);                                               \
  RECEIVER_T rcv_obj;                                                                          \
  function new ( RECEIVER_T _rcv_obj);                                                         \
    rcv_obj = _rcv_obj;                                                                        \
    `uvm_info(`"NAME_CB_OBJ`", {`"NAME_CB_OBJ`", "::new()"}, UVM_MEDIUM);                      \
  endfunction                                                                                  \
                                                                                               \
  virtual function void connect_to_callback();                                                 \
    string                monitor_name;                                                        \
    dv_monitor#(ITEM_T)   _monitor;                                                            \
    uvm_component         _monitor_list[$];                                                    \
                                                                                               \
    monitor_name = {AGENT_NAME,".monitor"};                                                    \
    `uvm_info(`"NAME_CB_OBJ`", {`"NAME_CB_OBJ`", "::connect()"}, UVM_MEDIUM);                  \
    `uvm_info(`"NAME_CB_OBJ`", {"Finding Monitor: ", monitor_name}, UVM_LOW);                  \
    uvm_top.find_all (monitor_name, _monitor_list);                                            \
    if (_monitor_list.size() > 1) begin                                                        \
      `uvm_fatal(`"NAME_CB_OBJ`", {monitor_name, " - Monitor Not Unique In The Environment.",  \
                                                   "Please Specify Unique Name"});             \
    end                                                                                        \
    else if (_monitor_list.size() == 0) begin                                                  \
      `uvm_fatal(`"NAME_CB_OBJ`", {monitor_name, " - Monitor Not Found In The Environment.",   \
                                                   "Please Specify Unique Name"});             \
    end                                                                                        \
    $cast (_monitor, _monitor_list[0]);                                                        \
    uvm_callbacks#(dv_monitor#(ITEM_T), dv_callback#(ITEM_T))::add(_monitor, this);            \
    `uvm_info(`"NAME_CB_OBJ`", {"Added Callback to ", monitor_name}, UVM_LOW);                 \
  endfunction                                                                                  \
                                                                                               \
  virtual function void indicated(ITEM_T trans);                                               \
    rcv_obj.``RECEIVER_FUNC(trans);                                                            \
  endfunction                                                                                  \
endclass
