; sys_memory_map_mkmon_a_192k.asm - written by dspmsg from system symbols.
;
; This DSP system include file contains memory-map pointers for the MKMON_A_192K case.
; The constants defined here change as a function of DSP memory size and 
; assembly configuration. 
;

;***** GLOBAL SYMBOLS *****
DEGMON_END_BUG56		 EQU $000096
DEGMON_H		 EQU $000095
DEGMON_L		 EQU $000034
DEGMON_N		 EQU $000062
I_0DBU16		 EQU $003187
I_0DBU24		 EQU $031999
I_ALIVE_PERIOD		 EQU $008000
I_DEFBCR		 EQU $000000
I_DEFIPR		 EQU $00243c
I_DEFOMR		 EQU $000006
I_DEFPLL		 EQU $260012
I_EPS		 EQU $000001
I_M12DBU16		 EQU $000c66
I_M12DBU24		 EQU $0c6666
I_MAXPOS		 EQU $7fffff
I_MINPOS		 EQU $000001
I_NTICK		 EQU $000010
I_ONEHALF		 EQU $400000
I_OUTY		 EQU $00ffff
LHE_USR		 EQU $0001ff
LHI_SYS		 EQU $000004
LHI_USR		 EQU $0000ff
LLE_USR		 EQU $000200
LLI_SYS		 EQU $000000
LLI_USR		 EQU $0000f6
NB_DMA		 EQU $000400
NB_DMA_R		 EQU $000200
NB_DMA_W		 EQU $000200
NB_DMQ		 EQU $000020
NB_HMS		 EQU $000080
NB_TMQ		 EQU $000800
NLE_USR		 EQU $000000
NLI_SYS		 EQU $000005
NLI_USR		 EQU $00000a
NPE_RAM		 EQU $00fe00
NPE_SYS		 EQU $000766
NPE_USR		 EQU $00f699
NPI_RAM		 EQU $000200
NPI_ROM		 EQU $000000
NPI_SYS		 EQU $000000
NPI_USR		 EQU $00016a
NXE_RAM		 EQU $00fdc0
NXE_SYS		 EQU $000067
NXE_USR		 EQU $00fd59
NXI_RAM		 EQU $000100
NXI_ROM		 EQU $000100
NXI_SYS		 EQU $000000
NXI_USR		 EQU $0000f1
NYE_RAM		 EQU $00fe00
NYE_SYS		 EQU $000ca0
NYE_USR		 EQU $00f160
NYI_RAM		 EQU $000100
NYI_ROM		 EQU $000100
NYI_SYS		 EQU $000000
NYI_USR		 EQU $0000f1
PHE_RAM		 EQU $00ffff
PHE_SYS		 EQU $00fffe
PHE_USR		 EQU $00f898
PHI_RAM		 EQU $0001ff
PHI_ROM		 EQU $0001ff
PHI_SYS		 EQU $000095
PHI_USR		 EQU $0001ff
PLE_RAM		 EQU $000200
PLE_SYS		 EQU $00f899
PLE_USR		 EQU $000200
PLI_RAM		 EQU $000000
PLI_ROM		 EQU $000200
PLI_SYS		 EQU $000096
PLI_USR		 EQU $000096
XHE_RAM		 EQU $00ffbf
XHE_SYS		 EQU $00ffbf
XHE_USR		 EQU $00ff58
XHI_RAM		 EQU $0000ff
XHI_ROM		 EQU $0001ff
XHI_SYS		 EQU $000004
XHI_USR		 EQU $0000f5
XLE_RAM		 EQU $000200
XLE_SYS		 EQU $00ff59
XLE_USR		 EQU $000200
XLI_RAM		 EQU $000000
XLI_ROM		 EQU $000100
XLI_SYS		 EQU $000000
XLI_USR		 EQU $000005
YHE_RAM		 EQU $00ffff
YHE_SYS		 EQU $00ffff
YHE_USR		 EQU $00f35f
YHI_RAM		 EQU $0000ff
YHI_ROM		 EQU $0001ff
YHI_SYS		 EQU $000004
YHI_USR		 EQU $0000f5
YLE_RAM		 EQU $000200
YLE_SYS		 EQU $00f360
YLE_USR		 EQU $000200
YLI_RAM		 EQU $000000
YLI_ROM		 EQU $000100
YLI_SYS		 EQU $000000
YLI_USR		 EQU $000005

;***** X SYMBOLS *****
	xdef X_ABORT_A1
X_ABORT_A1		 equ $00ff93
	xdef X_ABORT_DMASTAT
X_ABORT_DMASTAT		 equ $00ff91
	xdef X_ABORT_HCR
X_ABORT_HCR		 equ $00ff96
	xdef X_ABORT_HSR
X_ABORT_HSR		 equ $00ff97
	xdef X_ABORT_M_IO
X_ABORT_M_IO		 equ $00ff9b
	xdef X_ABORT_RUNSTAT
X_ABORT_RUNSTAT		 equ $00ff90
	xdef X_ABORT_R_HMS
X_ABORT_R_HMS		 equ $00ff98
	xdef X_ABORT_R_I1
X_ABORT_R_I1		 equ $00ff99
	xdef X_ABORT_R_IO
X_ABORT_R_IO		 equ $00ff9a
	xdef X_ABORT_SP
X_ABORT_SP		 equ $00ff94
	xdef X_ABORT_SR
X_ABORT_SR		 equ $00ff95
	xdef X_ABORT_X0
X_ABORT_X0		 equ $00ff92
	xdef X_ALIVE
X_ALIVE		 equ $00ffac
	xdef X_DMA1_R_M
X_DMA1_R_M		 equ $00ff70
	xdef X_DMA1_R_N
X_DMA1_R_N		 equ $00ff6f
	xdef X_DMA1_R_R
X_DMA1_R_R		 equ $00ff6e
	xdef X_DMA1_R_S
X_DMA1_R_S		 equ $00ff6d
	xdef X_DMASTAT
X_DMASTAT		 equ $000001
	xdef X_DMA_REB
X_DMA_REB		 equ $00ffb7
	xdef X_DMA_REN
X_DMA_REN		 equ $00ffb8
	xdef X_DMA_REP
X_DMA_REP		 equ $00ffb9
	xdef X_DMA_RFB
X_DMA_RFB		 equ $00ffb6
	xdef X_DMA_R_M
X_DMA_R_M		 equ $00ff68
	xdef X_DMA_R_N
X_DMA_R_N		 equ $00ff67
	xdef X_DMA_R_R
X_DMA_R_R		 equ $00ff66
	xdef X_DMA_R_S
X_DMA_R_S		 equ $00ff65
	xdef X_DMA_WEB
X_DMA_WEB		 equ $00ffb5
	xdef X_DMA_WFB
X_DMA_WFB		 equ $00ffb2
	xdef X_DMA_WFN
X_DMA_WFN		 equ $00ffb4
	xdef X_DMA_WFP
X_DMA_WFP		 equ $00ffb3
	xdef X_DMA_W_M
X_DMA_W_M		 equ $00ff6c
	xdef X_DMA_W_N
X_DMA_W_N		 equ $00ff6b
	xdef X_DMA_W_R
X_DMA_W_R		 equ $00ff6a
	xdef X_DMA_W_S
X_DMA_W_S		 equ $00ff69
	xdef X_DMQRP
X_DMQRP		 equ $00ff8b
	xdef X_DMQWP
X_DMQWP		 equ $00ff8c
	xdef X_DSPMSG_A1
X_DSPMSG_A1		 equ $00ff61
	xdef X_DSPMSG_B0
X_DSPMSG_B0		 equ $00ff60
	xdef X_DSPMSG_B1
X_DSPMSG_B1		 equ $00ff5f
	xdef X_DSPMSG_B2
X_DSPMSG_B2		 equ $00ff5e
	xdef X_DSPMSG_M_O
X_DSPMSG_M_O		 equ $00ff63
	xdef X_DSPMSG_R_O
X_DSPMSG_R_O		 equ $00ff62
	xdef X_DSPMSG_X0
X_DSPMSG_X0		 equ $00ff5d
	xdef X_DSPMSG_X1
X_DSPMSG_X1		 equ $00ff5c
	xdef X_HMSRP
X_HMSRP		 equ $00ff5a
	xdef X_HMSWP
X_HMSWP		 equ $00ff5b
	xdef X_IN_INCR
X_IN_INCR		 equ $00ffaf
	xdef X_IN_INITIAL_SKIP
X_IN_INITIAL_SKIP		 equ $00ffad
	xdef X_I_CHAN_OFFSET
X_I_CHAN_OFFSET		 equ $00ffaa
	xdef X_I_SFRAME_R
X_I_SFRAME_R		 equ $00ffa8
	xdef X_I_SFRAME_W
X_I_SFRAME_W		 equ $00ffa7
	xdef X_LARGS
X_LARGS		 equ $000004
	xdef X_NCHANS
X_NCHANS		 equ $00ff9e
	xdef X_NCLIP
X_NCLIP		 equ $00ff9f
	xdef X_OUT_INITIAL_SKIP
X_OUT_INITIAL_SKIP		 equ $00ffae
	xdef X_O_CHAN_COUNT
X_O_CHAN_COUNT		 equ $00ffa5
	xdef X_O_CHAN_OFFSET
X_O_CHAN_OFFSET		 equ $00ffa9
	xdef X_O_PADDING
X_O_PADDING		 equ $00ffab
	xdef X_O_SFRAME_R
X_O_SFRAME_R		 equ $00ffa4
	xdef X_O_SFRAME_W
X_O_SFRAME_W		 equ $00ffa3
	xdef X_O_TICK_SAMPS
X_O_TICK_SAMPS		 equ $00ffa6
	xdef X_SAVED_A0
X_SAVED_A0		 equ $00ff80
	xdef X_SAVED_A1
X_SAVED_A1		 equ $00ff7f
	xdef X_SAVED_A2
X_SAVED_A2		 equ $00ff7e
	xdef X_SAVED_B0
X_SAVED_B0		 equ $00ff83
	xdef X_SAVED_B1
X_SAVED_B1		 equ $00ff82
	xdef X_SAVED_B2
X_SAVED_B2		 equ $00ff81
	xdef X_SAVED_HOST_RCV1
X_SAVED_HOST_RCV1		 equ $00ff84
	xdef X_SAVED_HOST_RCV2
X_SAVED_HOST_RCV2		 equ $00ff85
	xdef X_SAVED_HOST_XMT1
X_SAVED_HOST_XMT1		 equ $00ff86
	xdef X_SAVED_HOST_XMT2
X_SAVED_HOST_XMT2		 equ $00ff87
	xdef X_SAVED_M_HMS
X_SAVED_M_HMS		 equ $00ff8a
	xdef X_SAVED_M_I1
X_SAVED_M_I1		 equ $00ff77
	xdef X_SAVED_M_I2
X_SAVED_M_I2		 equ $00ff78
	xdef X_SAVED_M_O
X_SAVED_M_O		 equ $00ff79
	xdef X_SAVED_N_HMS
X_SAVED_N_HMS		 equ $00ff89
	xdef X_SAVED_N_I1
X_SAVED_N_I1		 equ $00ff74
	xdef X_SAVED_N_I2
X_SAVED_N_I2		 equ $00ff75
	xdef X_SAVED_N_O
X_SAVED_N_O		 equ $00ff76
	xdef X_SAVED_REGISTERS
X_SAVED_REGISTERS		 equ $00ff71
	xdef X_SAVED_R_HMS
X_SAVED_R_HMS		 equ $00ff88
	xdef X_SAVED_R_I1
X_SAVED_R_I1		 equ $00ff71
	xdef X_SAVED_R_I1_HMLIB
X_SAVED_R_I1_HMLIB		 equ $00ff9d
	xdef X_SAVED_R_I2
X_SAVED_R_I2		 equ $00ff72
	xdef X_SAVED_R_O
X_SAVED_R_O		 equ $00ff73
	xdef X_SAVED_SR
X_SAVED_SR		 equ $00ff9c
	xdef X_SAVED_X0
X_SAVED_X0		 equ $00ff7b
	xdef X_SAVED_X1
X_SAVED_X1		 equ $00ff7a
	xdef X_SAVED_Y0
X_SAVED_Y0		 equ $00ff7d
	xdef X_SAVED_Y1
X_SAVED_Y1		 equ $00ff7c
	xdef X_SCI_COUNT
X_SCI_COUNT		 equ $00ffa0
	xdef X_SCRATCH1
X_SCRATCH1		 equ $00ff8d
	xdef X_SCRATCH2
X_SCRATCH2		 equ $00ff8e
	xdef X_SSI_REB
X_SSI_REB		 equ $00ffbd
	xdef X_SSI_REN
X_SSI_REN		 equ $00ffbc
	xdef X_SSI_REP
X_SSI_REP		 equ $00ffbb
	xdef X_SSI_RFB
X_SSI_RFB		 equ $00ffba
	xdef X_SSI_SAVED_1
X_SSI_SAVED_1		 equ $00ffb0
	xdef X_SSI_SAVED_2
X_SSI_SAVED_2		 equ $00ffb1
	xdef X_SSI_SBUFS
X_SSI_SBUFS		 equ $00ffbe
	xdef X_SSI_SBUFS_GOAL
X_SSI_SBUFS_GOAL		 equ $00ffbf
	xdef X_START
X_START		 equ $00ff59
	xdef X_SYS_CALL_ARG
X_SYS_CALL_ARG		 equ $00ff8f
	xdef X_TICK
X_TICK		 equ $000002
	xdef X_TMQRP
X_TMQRP		 equ $00ffa1
	xdef X_TMQWP
X_TMQWP		 equ $00ffa2
	xdef X_XHM_R_I1
X_XHM_R_I1		 equ $00ff64
	xdef X_ZERO
X_ZERO		 equ $000000

;***** Y SYMBOLS *****
	xdef YB_DMA_R
YB_DMA_R		 equ $00f400
	xdef YB_DMA_R0
YB_DMA_R0		 equ $00f400
	xdef YB_DMA_R2
YB_DMA_R2		 equ $00f500
	xdef YB_DMA_W
YB_DMA_W		 equ $00f600
	xdef YB_DMA_W0
YB_DMA_W0		 equ $00f600
	xdef YB_DMA_W2
YB_DMA_W2		 equ $00f700
	xdef YB_DMQ
YB_DMQ		 equ $00f360
	xdef YB_DMQ0
YB_DMQ0		 equ $00f360
	xdef YB_HMS
YB_HMS		 equ $00f380
	xdef YB_HMS0
YB_HMS0		 equ $00f380
	xdef YB_TMQ
YB_TMQ		 equ $00f800
	xdef YB_TMQ0
YB_TMQ0		 equ $00f800
	xdef YB_TMQ2
YB_TMQ2		 equ $00fc00
	xdef Y_DEVSTAT
Y_DEVSTAT		 equ $000004
	xdef Y_RUNSTAT
Y_RUNSTAT		 equ $000001
	xdef Y_TICK
Y_TICK		 equ $000002
	xdef Y_TINC
Y_TINC		 equ $000003
	xdef Y_ZERO
Y_ZERO		 equ $000000

;***** L SYMBOLS *****
	xdef L_LARGS_DEVSTAT
L_LARGS_DEVSTAT		 equ $000004
	xdef L_STATUS
L_STATUS		 equ $000001
	xdef L_TICK
L_TICK		 equ $000002
	xdef L_TINC
L_TINC		 equ $000003
	xdef L_ZERO
L_ZERO		 equ $000000