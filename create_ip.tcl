
create_project -force dflow_packet_generator ./dflow_packet_generator_vivado/dflow_packet_generator -part xc7z045ffg676-2

add_files -norecurse -scan_for_includes {./src/genevr_pipeline_regs.v ./src/fallthrough_small_fifo_v2.v ./src/axi_to_reg_bus.v ./src/fifo_to_mem.v ./src/xil_async_fifo.v ./src/dflow_generator_core.v ./src/dflow_generator.v ./src/inqueue.v ./src/mem_to_fifo.v ./src/outqueue.v ./src/small_fifo_v3.v}
import_files -norecurse {./src/genevr_pipeline_regs.v ./src/fallthrough_small_fifo_v2.v ./src/axi_to_reg_bus.v ./src/fifo_to_mem.v ./src/xil_async_fifo.v ./src/dflow_generator_core.v ./src/dflow_generator.v ./src/inqueue.v ./src/mem_to_fifo.v ./src/outqueue.v ./src/small_fifo_v3.v}
update_compile_order -fileset sources_1
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse -scan_for_includes {./testbench/dflow_generator_test.v ./testbench/inqueue_test.v}
import_files -fileset sim_1 -norecurse {./testbench/dflow_generator_test.v ./testbench/inqueue_test.v}
update_compile_order -fileset sim_1

import_files  ./src/ip_core/reg_access_fifo/reg_access_fifo.xci
export_ip_user_files -of_objects [get_files  ./dflow_packet_generator_vivado/dflow_packet_generator/dflow_packet_generator.srcs/sources_1/ip/reg_access_fifo/reg_access_fifo.xci] -force -quiet
update_compile_order -fileset sources_1


ipx::package_project -root_dir ./dflow_packet_generator_vivado/dflow_packet_generator/dflow_packet_generator.srcs -vendor xilinx.com -library user -taxonomy /UserIP
set_property core_revision 2 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
set_property  ip_repo_paths  ./dflow_packet_generator_vivado/dflow_packet_generator/dflow_packet_generator.srcs [current_project]
update_ip_catalog

