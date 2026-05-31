#!/bin/bash

RTL=../rtl
TB=../tb
PDK=/pdk/synopsys/saed32/SAED32_EDK/lib/stdcell_rvt/verilog

echo "Compilando..."

vcs \
-sverilog \
-kdb \
-lca \
-debug_access+all+reverse \
-cm line+tgl+fsm+branch+cond \
$TB/top_tb.sv \
$RTL/register_bank.sv \
$RTL/mux4.sv \
$RTL/control.sv \
$RTL/memory.sv \
$RTL/ALU.sv \
$RTL/top.sv \
-v $PDK/saed32nm.v

echo "Simulando..."

./simv \
+FSDB_ON \
+fsdbfile+inter.fsdb \
-l new.log \
-cm line+cond+fsm+tgl+branch+assert

echo "Abrindo Verdi..."

verdi -cov -covdir simv.vdb/