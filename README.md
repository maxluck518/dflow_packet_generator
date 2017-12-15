# dflow_packet_generator
packet generator for dflow experiment

## Content
```

.
├── create_ip.tcl
├── README.md
├── src
│   ├── import
│   │   ├── axi_to_reg_bus.v
│   │   ├── dflow_generator_core.v
│   │   ├── dflow_generator_datapath.v
│   │   ├── dflow_generator.v
│   │   ├── fallthrough_small_fifo_v2.v
│   │   ├── fifo_to_mem.v
│   │   ├── genevr_pipeline_regs.v
│   │   ├── inqueue.v
│   │   ├── mem_to_fifo.v
│   │   ├── outqueue.v
│   │   └── small_fifo_v3.v
│   └── ip
│       ├── reg_access_fifo
│       ├── xil_async_fifo_in
│       └── xil_async_fifo_out
└── testbench
    ├── dflow_generator_datapath_test.v
    ├── dflow_generator_test.v
    ├── inqueue_test.v
    └── outqueue_test.v
    
```

## DataFlow

```
graph LR
	IN--pkt_info-->inqueue
	inqueue-->fifo_to_mem
	fifo_to_mem--wr-->QDR
	QDR--rd-->mem_to_fifo
	mem_to_fifo-->outqueue
	outqueue--pkt_info-->out
	reg--start_store-->fifo_to_mem
	reg--start_replay-->mem_to_fifo
	reg---|axi|Zynq	
```

## RegFile

| signal           | width(bit) | address    |
| ---------------- | ---------- | ---------- |
| sw_rst           | 1          | 0x444005c0 |
| start_store      | 1          | 0x444005c4 |
| start_replay     | 1          | 0x444005c8 |
| mem_addr_low     | 19         | 0x444005d0 |
| mem_addr_high    | 19         | 0x444005d4 |
| compelete_store  | 1          | 0x44c005c0 |
| compelete_replay | 1          | 0x44c005c1 |

To be continued!