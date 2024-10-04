#
# Topology for Icelake with rt711 + rt1308 (x2) + rt715.
#

# Include topology builder
include(`utils.m4')
include(`dai.m4')
include(`pipeline.m4')
include(`alh.m4')
include(`muxdemux.m4')
include(`hda.m4')

# Include TLV library
include(`common/tlv.m4')

# Include Token library
include(`sof/tokens.m4')

# Include Platform specific DSP configuration
include(`platform/intel/'PLATFORM`.m4')

ifdef(`SDW_LINK',`',
`define(SDW_LINK, `0')')

# uncomment to remove HDMI support
#define(NOHDMI, `1')

# UAJ ID: 0, 1
# AMP ID: 2, 3 (if EXT_AMP_REF defined)
# DMIC ID: 4
# HDMI ID calculated based on the configuraiton
define(HDMI_BE_ID_BASE, `0')

ifdef(`NO_JACK', `',
	`undefine(`HDMI_BE_ID_BASE')
	 define(HDMI_BE_ID_BASE, `2')'
)

ifdef(`NOAMP', `',
	`undefine(`HDMI_BE_ID_BASE')
	 define(HDMI_BE_ID_BASE, `3')'
)

ifdef(`EXT_AMP_REF',
	`undefine(`HDMI_BE_ID_BASE')
	 define(HDMI_BE_ID_BASE, `4')',
	`'
)

ifdef(`NO_LOCAL_MIC', `',
	`undefine(`HDMI_BE_ID_BASE')
	 define(HDMI_BE_ID_BASE, `5')'
)

DEBUG_START

#
# Define the pipelines
#
ifdef(`NOJACK', `',
`
# PCM0 ---> volume ----> mixer --->ALH 2 BE SDW_LINK
# PCM31 ---> volume ------^
# PCM1 <--- volume <---- ALH 3 BE SDW_LINK
')
ifdef(`NOAMP', `',
`
# PCM2 ---> volume ----> ALH 2 BE SDW_LINK
ifdef(`MONO', `',
`# PCM40 ---> volume ----> ALH 4 BE SDW_LINK')
')
ifdef(`NO_LOCAL_MIC', `',
`# PCM4 <--- volume <---- ALH 5 BE SDW_LINK')

ifdef(`NOHDMI', `',
`
# PCM5 ---> volume ----> iDisp1
# PCM6 ---> volume ----> iDisp2
# PCM7 ---> volume ----> iDisp3
')

dnl PIPELINE_PCM_ADD(pipeline,
dnl     pipe id, pcm, max channels, format,
dnl     period, priority, core,
dnl     pcm_min_rate, pcm_max_rate, pipeline_rate,
dnl     time_domain, sched_comp)

ifdef(`NOJACK', `',
`
# Low Latency capture pipeline 2 on PCM 1 using max 2 channels of s32le.
# Schedule 48 frames per 1000us deadline with priority 0 on core 0
PIPELINE_PCM_ADD(sof/pipe-volume-switch-capture.m4,
	2, 1, 2, s32le,
	1000, 0, 0,
	48000, 48000, 48000)
')

ifdef(`NOAMP', `',
`
# Low Latency playback pipeline 3 on PCM 2 using max 2 channels of s32le.
# Schedule 48 frames per 1000us deadline with priority 0 on core 0
PIPELINE_PCM_ADD(sof/pipe-volume-playback.m4,
	3, 2, 2, s32le,
	1000, 0, 0,
	48000, 48000, 48000)
')

ifdef(`NO_LOCAL_MIC', `',
`
# Low Latency capture pipeline 5 on PCM 4 using max 2 channels of s32le.
# Schedule 48 frames per 1000us deadline with priority 0 on core 0
PIPELINE_PCM_ADD(sof/pipe-highpass-switch-capture.m4,
	5, 4, 2, s32le,
	1000, 0, 0,
	48000, 48000, 48000)
')

# Low Latency playback pipeline 6 on PCM 5 using max 2 channels of s32le.
# Schedule 48 frames per 1000us deadline with priority 0 on core 0
PIPELINE_PCM_ADD(sof/pipe-volume-playback.m4,
	6, 5, 2, s32le,
	1000, 0, 0,
	48000, 48000, 48000)

# Low Latency playback pipeline 7 on PCM 6 using max 2 channels of s32le.
# Schedule 48 frames per 1000us deadline with priority 0 on core 0
PIPELINE_PCM_ADD(sof/pipe-volume-playback.m4,
	7, 6, 2, s32le,
	1000, 0, 0,
	48000, 48000, 48000)

# Low Latency playback pipeline 8 on PCM 7 using max 2 channels of s32le.
# Schedule 48 frames per 1000us deadline with priority 0 on core 0
PIPELINE_PCM_ADD(sof/pipe-volume-playback.m4,
	8, 7, 2, s32le,
	1000, 0, 0,
	48000, 48000, 48000)

#
# DAIs configuration
#

dnl DAI_ADD(pipeline,
dnl     pipe id, dai type, dai_index, dai_be,
dnl     buffer, periods, format,
dnl     deadline, priority, core, time_domain)

ifdef(`NOJACK', `',
`
# playback DAI is ALH(SDW_LINK PIN2) using 2 periods
# Buffers use s24le format, with 48 frame per 1000us on core 0 with priority 0
# The NOT_USED_IGNORED is due to dependencies and is adjusted later with an explicit dapm line.

DAI_ADD(sof/pipe-mixer-volume-dai-playback.m4,
	1, ALH, eval(SDW_LINK * 256 + 2), Playback-SimpleJack,
	NOT_USE_IGNORED, 2, s24le,
	1000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER, 2, 48000)

# capture DAI is ALH(SDW_LINK PIN3) using 2 periods
# Buffers use s24le format, with 48 frame per 1000us on core 0 with priority 0
DAI_ADD(sof/pipe-dai-capture.m4,
	2, ALH, eval(SDW_LINK * 256 + 3), Capture-SimpleJack,
	PIPELINE_SINK_2, 2, s24le,
	1000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)

# Low Latency playback pipeline 30 on PCM 0 using max 2 channels of s32le.
# Schedule 48 frames per 1000us deadline on core 0 with priority 0
PIPELINE_PCM_ADD(sof/pipe-host-volume-playback.m4,
	30, 0, 2, s32le,
	1000, 0, 0,
	48000, 48000, 48000,
	SCHEDULE_TIME_DOMAIN_TIMER,
	PIPELINE_PLAYBACK_SCHED_COMP_1)

# Deep buffer playback pipeline 31 on PCM 31 using max 2 channels of s32le
# Set 1000us deadline on core 0 with priority 0.
# TODO: Modify pipeline deadline to account for deep buffering
ifdef(`HEADSET_DEEP_BUFFER',
`
PIPELINE_PCM_ADD(sof/pipe-host-volume-playback.m4,
	31, 31, 2, s32le,
	1000, 0, 0,
	48000, 48000, 48000,
	SCHEDULE_TIME_DOMAIN_TIMER,
	PIPELINE_PLAYBACK_SCHED_COMP_1)
'
)

SectionGraph."mixer-host" {
	index "0"

	lines [
		# connect mixer dai pipelines to PCM pipelines
		dapm(PIPELINE_MIXER_1, PIPELINE_SOURCE_30)
ifdef(`HEADSET_DEEP_BUFFER',
`
		dapm(PIPELINE_MIXER_1, PIPELINE_SOURCE_31)
'
)
	]
}

'
)

ifdef(`NOAMP', `',
`
# playback DAI is ALH(SDW_LINK PIN4) using 2 periods
# Buffers use s24le format, with 48 frame per 1000us on core 0 with priority 0
DAI_ADD(sof/pipe-dai-playback.m4,
	3, ALH, eval(SDW_LINK * 256 + 4), Playback-SmartAmp,
	PIPELINE_SOURCE_3, 2, s24le,
	1000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)
')

ifdef(`NO_LOCAL_MIC', `',
`
# capture DAI is ALH(SDW_LINK PIN5) using 2 periods
# Buffers use s24le format, with 48 frame per 1000us on core 0 with priority 0
DAI_ADD(sof/pipe-dai-capture.m4,
	5, ALH, eval(SDW_LINK * 256 + 5), Capture-SmartMic,
	PIPELINE_SINK_5, 2, s24le,
	1000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)
')

ifdef(`NOHDMI', `',
`
# playback DAI is iDisp1 using 2 periods
# # Buffers use s32le format, 1000us deadline with priority 0 on core 0
DAI_ADD(sof/pipe-dai-playback.m4,
	6, HDA, 0, iDisp1,
	PIPELINE_SOURCE_6, 2, s32le,
	1000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)

# playback DAI is iDisp2 using 2 periods
# # Buffers use s32le format, 1000us deadline with priority 0 on core 0
DAI_ADD(sof/pipe-dai-playback.m4,
	7, HDA, 1, iDisp2,
	PIPELINE_SOURCE_7, 2, s32le,
	1000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)

# playback DAI is iDisp3 using 2 periods
# # Buffers use s32le format, 1000us deadline with priority 0 on core 0
DAI_ADD(sof/pipe-dai-playback.m4,
	8, HDA, 2, iDisp3,
	PIPELINE_SOURCE_8, 2, s32le,
	1000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)
')

# PCM Low Latency, id 0
dnl PCM_PLAYBACK_ADD(name, pcm_id, playback)

ifdef(`NOJACK', `',
`
PCM_PLAYBACK_ADD(Jack Out, 0, PIPELINE_PCM_30)
ifdef(`HEADSET_DEEP_BUFFER',
`
PCM_PLAYBACK_ADD(Jack Out DeepBuffer, 31, PIPELINE_PCM_31)
'
)
PCM_CAPTURE_ADD(Jack In, 1, PIPELINE_PCM_2)
')
ifdef(`NOAMP', `',
`
PCM_PLAYBACK_ADD(Speaker, 2, PIPELINE_PCM_3)
')
ifdef(`NO_LOCAL_MIC', `', `PCM_CAPTURE_ADD(Microphone, 4, PIPELINE_PCM_5)')

ifdef(`NOHDMI', `',
`
PCM_PLAYBACK_ADD(HDMI 1, 5, PIPELINE_PCM_6)
PCM_PLAYBACK_ADD(HDMI 2, 6, PIPELINE_PCM_7)
PCM_PLAYBACK_ADD(HDMI 3, 7, PIPELINE_PCM_8)
')

#
# BE configurations - overrides config in ACPI if present
#

ifdef(`NOJACK', `',
`
#ALH dai index = ((link_id << 8) | PDI id)
#ALH SDW_LINK Pin2 (ID: 0)
DAI_CONFIG(ALH, eval(SDW_LINK * 256 + 2), 0, Playback-SimpleJack,
	ALH_CONFIG(ALH_CONFIG_DATA(ALH, eval(SDW_LINK * 256 + 2), 48000, 2)))

#ALH SDW_LINK Pin3 (ID: 1)
DAI_CONFIG(ALH, eval(SDW_LINK * 256 + 3), 1, Capture-SmartMic,
	ALH_CONFIG(ALH_CONFIG_DATA(ALH, eval(SDW_LINK * 256 + 3), 48000, 2)))
')

ifdef(`NOAMP', `',
`
#ALH SDW_LINK Pin4 (ID: 2)
DAI_CONFIG(ALH, eval(SDW_LINK * 256 + 4), 2, Playback-SmartAmp,
	ALH_CONFIG(ALH_CONFIG_DATA(ALH, eval(SDW_LINK * 256 + 4), 48000, 2)))
')

ifdef(`NO_LOCAL_MIC', `',
`
#ALH SDW_LINK Pin5 (ID: 4)
DAI_CONFIG(ALH, eval(SDW_LINK * 256 + 5), 4, Capture-SmartMic,
	ALH_CONFIG(ALH_CONFIG_DATA(ALH, eval(SDW_LINK * 256 + 5), 48000, 2)))
')

ifdef(`NOHDMI', `',
`
# 3 HDMI/DP outputs (ID: from HDMI_BE_ID_BASE)
DAI_CONFIG(HDA, 0, HDMI_BE_ID_BASE, iDisp1,
	HDA_CONFIG(HDA_CONFIG_DATA(HDA, 0, 48000, 2)))
DAI_CONFIG(HDA, 1, eval(HDMI_BE_ID_BASE + 1), iDisp2,
	HDA_CONFIG(HDA_CONFIG_DATA(HDA, 1, 48000, 2)))
DAI_CONFIG(HDA, 2, eval(HDMI_BE_ID_BASE + 2), iDisp3,
	HDA_CONFIG(HDA_CONFIG_DATA(HDA, 2, 48000, 2)))
')

DEBUG_END
