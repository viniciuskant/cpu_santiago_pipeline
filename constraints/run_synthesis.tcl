source ../scripts/setup.tcl

# =========================================================
# Cria identificador único para cada run
# =========================================================
set RUN_NAME [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]

set RUN_DIR "../runs/$RUN_NAME"

set REPORTS_DIR "$RUN_DIR/reports"
set OUTPUTS_DIR "$RUN_DIR/outputs"
set LOGS_DIR "$RUN_DIR/logs"
set SNAPSHOT_DIR "$RUN_DIR/snapshots"

# =========================================================
# Cria estrutura de diretórios
# =========================================================
if {![file isdirectory $RUN_DIR]} {
    file mkdir $RUN_DIR
}

if {![file isdirectory $REPORTS_DIR]} {
    file mkdir $REPORTS_DIR
}

if {![file isdirectory $OUTPUTS_DIR]} {
    file mkdir $OUTPUTS_DIR
}

if {![file isdirectory $LOGS_DIR]} {
    file mkdir $LOGS_DIR
}

if {![file isdirectory $SNAPSHOT_DIR]} {
    file mkdir $SNAPSHOT_DIR
}

# Salva snapshot dos scripts/constraints usados
file copy -force ../scripts/run_synthesis.tcl $SNAPSHOT_DIR/
file copy -force ../scripts/setup.tcl $SNAPSHOT_DIR/
file copy -force ../constraints/cons.tcl $SNAPSHOT_DIR/

# Logic library setup:
# TODO: achar biblioteca de células densas, acho que não tem: io_sp  io_std  oa  opensparc  pll  references  sram  sram_lp  stdcell_hvt  stdcell_lvt	stdcell_rvt
set_app_var synthetic_library dw_foundation.sldb
set_app_var search_path "~/lab_cpu/rtl ${DB_PATH}"
set_app_var target_library "saed32rvt_tt1p05v25c.db" 
set_app_var link_library "* $target_library $synthetic_library"

## Cria diretório work se não existir
set work_path "../work"

if {![file isdirectory $work_path]} {
    file mkdir $work_path
}

# Limpa designs anteriores e define WORK
remove_design -all
define_design_lib WORK -path $work_path

# como inclui no search não preciso colocar a pasta, pense no 
# search como um export no PATH
analyze -format sverilog register_bank.sv
analyze -format sverilog mux4.sv
analyze -format sverilog ALU.sv
analyze -format sverilog control.sv
analyze -format sverilog memory.sv
analyze -format sverilog top.sv

elaborate top

list_designs
report_design_lib WORK

current_design top

link

check_design

source ../constraints/cons.tcl
compile_ultra -scan

######################dft
create_test_protocol -infer_clock -infer_asynch
dft_drc 
preview_dft 
insert_dft
dft_drc
compile_ultra -incr -scan
dft_drc
########################




#Aplica constraints
compile -incremental -area_effort high

# =========================================================
# Salva netlists/resultados
# =========================================================

write -format verilog -hierarchy \
    -output $OUTPUTS_DIR/top_syn.v

write_file -format ddc -hierarchy \
    -output $OUTPUTS_DIR/top.ddc

write_sdc $OUTPUTS_DIR/top.sdc

# reportar resultados
redirect $REPORTS_DIR/area.rpt {
    report_area
}

redirect $REPORTS_DIR/timing.rpt {
    report_timing
}

redirect $REPORTS_DIR/power.rpt {
    report_power
}

# redirect $REPORTS_DIR/qor.rpt {
#     report_qor
# }

# redirect $REPORTS_DIR/reference.rpt {
#     report_reference
# }

# redirect $REPORTS_DIR/constraint.rpt {
#     report_constraint -all_violators
# }
redirect $REPORTS_DIR/fsm.rpt {
    report_fsm -verbose
}

report_scan_path -view existing_dft -chain all
report_constraints -all_violators
write_scan_def -output $REPORTS_DIR/dft.scandef

echo "Synthesis completed successfully!"
echo "Run directory: $RUN_DIR"