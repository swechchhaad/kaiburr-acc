# Clock and Reset UVM Agent

Clock and reset UVM Agent extended from DV library/UVM agent classes.

## Description

This agent is responsible for driving the clock and reset in a testbench. 
If there are more than one clock/reset domain each domain will contain its own clock reset agent. 

A delay_agent is also part of the clk_rst_agent package and provides a way to consume time at a
sequence using the delay_sequence that can execute on the delay_agent.
