# dflow_packet_generator
packet generator for dflow experiment

## Content
    .
    ├── README.md
    ├── src
    │   ├── dflow_generator_core.v
    │   ├── dflow_generator.v
    │   ├── fallthrough_small_fifo_v2.v
    │   ├── fifo_to_mem.v
    │   ├── inqueue.v
    │   ├── mem_to_fifo.v
    │   ├── outqueue.v
    │   └── small_fifo_v3.v
    └── testbench
        ├── inqueue_test.v
        └── outqueue_test.v

## DataFlow

```mermaid
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

To be continued!