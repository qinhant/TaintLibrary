analyze -sv buffered_mul_taint_precise.sv
elaborate -top buffered_mul_taint

clock clk
reset rst

check_spv -create -from {in_a in_b} -to {out_valid}
assert {in_a_t -> !out_valid_t}

set_prove_time_limit 3600
prove -all