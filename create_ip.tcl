create_project -force dflow_packet_generator ./dflow_packet_generator_vivado/dflow_packet_generator -part xc7z045ffg676-2

add_files -scan_for_includes ./src/import
import_files ./src/import

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -scan_for_includes ./testbench
import_files -fileset sim_1 ./testbench

import_files  {./src/ip/xil_async_fifo_in/xil_async_fifo_in.xci ./src/ip/xil_async_fifo_out/xil_async_fifo_out.xci ./src/ip/reg_access_fifo/reg_access_fifo.xci}
export_ip_user_files -of_objects [get_files  {./dflow_packet_generator_vivado/dflow_packet_generator/dflow_packet_generator.srcs/sources_1/ip/xil_async_fifo_in/xil_async_fifo_in.xci ./dflow_packet_generator_vivado/dflow_packet_generator/dflow_packet_generator.srcs/sources_1/ip/xil_async_fifo_out/xil_async_fifo_out.xci ./dflow_packet_generator_vivado/dflow_packet_generator/dflow_packet_generator.srcs/sources_1/ip/reg_access_fifo/reg_access_fifo.xci}] -force -quiet

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

ipx::package_project -root_dir ./dflow_packet_generator_vivado/dflow_packet_generator/dflow_packet_generator.srcs/sources_1 -vendor xilinx.com -library user -taxonomy /UserIP
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces s_axi_aclk -of_objects [ipx::current_core]]

set_property value s_axi [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces s_axi_aclk -of_objects [ipx::current_core]]]

ipx::remove_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces clk -of_objects [ipx::current_core]]


set_property core_revision 1 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
set_property  ip_repo_paths  ./dflow_packet_generator_vivado/dflow_packet_generator/dflow_packet_generator.srcs/sources_1 [current_project]
update_ip_catalog

ipx::merge_project_changes files [ipx::current_core]


