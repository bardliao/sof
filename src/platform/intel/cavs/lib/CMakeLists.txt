# SPDX-License-Identifier: BSD-3-Clause

add_local_sources(sof
	dai.c
	dma.c
	memory.c
	pm_runtime.c
	pm_memory.c
	power_down.S
)

if(CONFIG_MEM_WND)
	add_local_sources(sof mem_window.c)
endif()
