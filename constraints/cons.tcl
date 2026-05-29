#return
set clk_val 5.55
create_clock -period $clk_val [get_ports clk] -name clk
set_clock_uncertainty 0.3 [get_clocks clk]
# Era o do Ulisses
# set_clock_uncertainty -setup [expr $clk_val*0.1] [get_clocks clk]
set_clock_transition -max [expr $clk_val*0.1] [get_clocks clk]
# set_clock_latency -source -max [expr $clk_val*0.05] [get_clocks clk]
# set_clock_latency -max [expr $clk_val*0.03] [get_clocks clk]
set_clock_transition -rise 0.1 [get_clocks clk]
set_clock_transition -fall 0.1 [get_clocks clk]

# Era o do Ulisses
set_input_delay 2.0 -clock clk [get_ports [remove_from_collection [all_inputs] clk]]
set_output_delay 2.0 -clock clk [get_ports [all_outputs]]

set_load -max 0.04 [all_outputs]
set_input_transition -min [expr $clk_val*0.01] [remove_from_collection [all_inputs] clk]
set_input_transition -max [expr $clk_val*0.1] [remove_from_collection [all_inputs] clk]
#return

set_max_area 3500

set_fsm_minimize true

ungroup -all -flatten

set_optimize_registers true
optimize_netlist -area -no_boundary_optimization
# set_boundary_optimization true