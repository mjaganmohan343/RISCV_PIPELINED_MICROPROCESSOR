# Create a 83.46 MHz clock (12.000 ns period) on the 'clk' port
create_clock -period 13.800 -name clk -waveform {0.000 6.900} [get_ports clk]
# Since we are using an XOR reduction for our single output, we can add a simple 
# output delay to prevent Vivado from warning about unconstrained endpoints.
# (This step is optional but considered good practice)
set_output_delay -clock [get_clocks clk] 1.000 [get_ports dummy_out]
