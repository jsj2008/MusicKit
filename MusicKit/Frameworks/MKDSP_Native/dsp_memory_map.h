#ifndef __MK_dsp_memory_map_H___
#define __MK_dsp_memory_map_H___
/* dsp_memory_map.h - written by dspmsg from system symbols.

This include file contains definitions for DSP memory addresses.
The values depend heavily on /usr/lib/dsp/smsrc/config.asm, and they
tend to change every time the DSP system code is modified.
Address names are of the form 

		DSP_{X,Y,P,L}{L,H}{I,E}_{USR,SYS}

where {X,Y,P,L} are the possible memory spaces in the DSP, {L,H} specifies 
lower or higher memory segment boundary, {I,E} specifies internal or 
external memory, and {USR,SYS} specifies user or system memory segments. 
For example, PHE_USR specifies the maximum address available to the user 
in external program memory.  In general, the system occupies the lowest and 
highest address range in each space, with the user having all addresses in 
between.

Names of the form 'DSP_I_<name>' denote integer constants.
Names of the form 'DSP_NB_<name>' denote buffer sizes.
Names of the form 'DSP_N{X,Y,L,P}{I,E}_{USR,SYS}' denote memory segment sizes.
*/ 

/***** GLOBAL SYMBOLS *****/
#define DSP_DEGMON_END_BUG56 DSPGetSystemSymbolValueInLC("DEGMON_END_BUG56", DSP_LC_N)
#define DSP_DEGMON_H DSPGetSystemSymbolValueInLC("DEGMON_H", DSP_LC_N)
#define DSP_DEGMON_L DSPGetSystemSymbolValueInLC("DEGMON_L", DSP_LC_N)
#define DSP_DEGMON_N DSPGetSystemSymbolValueInLC("DEGMON_N", DSP_LC_N)
#define DSP_HE_USR DSPGetSystemSymbolValueInLC("HE_USR", DSP_LC_N)
#define DSP_I_0DBU16 DSPGetSystemSymbolValueInLC("I_0DBU16", DSP_LC_N)
#define DSP_I_0DBU24 DSPGetSystemSymbolValueInLC("I_0DBU24", DSP_LC_N)
#define DSP_I_DEFBCR DSPGetSystemSymbolValueInLC("I_DEFBCR", DSP_LC_N)
#define DSP_I_DEFIPR DSPGetSystemSymbolValueInLC("I_DEFIPR", DSP_LC_N)
#define DSP_I_DEFOMR DSPGetSystemSymbolValueInLC("I_DEFOMR", DSP_LC_N)
#define DSP_I_EPS DSPGetSystemSymbolValueInLC("I_EPS", DSP_LC_N)
#define DSP_I_M12DBU16 DSPGetSystemSymbolValueInLC("I_M12DBU16", DSP_LC_N)
#define DSP_I_M12DBU24 DSPGetSystemSymbolValueInLC("I_M12DBU24", DSP_LC_N)
#define DSP_I_MAXPOS DSPGetSystemSymbolValueInLC("I_MAXPOS", DSP_LC_N)
#define DSP_I_MINPOS DSPGetSystemSymbolValueInLC("I_MINPOS", DSP_LC_N)
#define DSP_I_NTICK DSPGetSystemSymbolValueInLC("I_NTICK", DSP_LC_N)
#define DSP_I_ONEHALF DSPGetSystemSymbolValueInLC("I_ONEHALF", DSP_LC_N)
#define DSP_I_OUTY DSPGetSystemSymbolValueInLC("I_OUTY", DSP_LC_N)
#define DSP_LE_USR DSPGetSystemSymbolValueInLC("LE_USR", DSP_LC_N)
#define DSP_LHE_USR DSPGetSystemSymbolValueInLC("LHE_USR", DSP_LC_N)
#define DSP_LHI_SYS DSPGetSystemSymbolValueInLC("LHI_SYS", DSP_LC_N)
#define DSP_LHI_USR DSPGetSystemSymbolValueInLC("LHI_USR", DSP_LC_N)
#define DSP_LLE_USR DSPGetSystemSymbolValueInLC("LLE_USR", DSP_LC_N)
#define DSP_LLI_SYS DSPGetSystemSymbolValueInLC("LLI_SYS", DSP_LC_N)
#define DSP_LLI_USR DSPGetSystemSymbolValueInLC("LLI_USR", DSP_LC_N)
#define DSP_NAE_SYS DSPGetSystemSymbolValueInLC("NAE_SYS", DSP_LC_N)
#define DSP_NB_DMA DSPGetSystemSymbolValueInLC("NB_DMA", DSP_LC_N)
#define DSP_NB_DMA_R DSPGetSystemSymbolValueInLC("NB_DMA_R", DSP_LC_N)
#define DSP_NB_DMA_W DSPGetSystemSymbolValueInLC("NB_DMA_W", DSP_LC_N)
#define DSP_NB_DMQ DSPGetSystemSymbolValueInLC("NB_DMQ", DSP_LC_N)
#define DSP_NB_HMS DSPGetSystemSymbolValueInLC("NB_HMS", DSP_LC_N)
#define DSP_NB_TMQ DSPGetSystemSymbolValueInLC("NB_TMQ", DSP_LC_N)
#define DSP_NE_USR DSPGetSystemSymbolValueInLC("NE_USR", DSP_LC_N)
#define DSP_NLE_USR DSPGetSystemSymbolValueInLC("NLE_USR", DSP_LC_N)
#define DSP_NLI_SYS DSPGetSystemSymbolValueInLC("NLI_SYS", DSP_LC_N)
#define DSP_NLI_USR DSPGetSystemSymbolValueInLC("NLI_USR", DSP_LC_N)
#define DSP_NPE_RAM DSPGetSystemSymbolValueInLC("NPE_RAM", DSP_LC_N)
#define DSP_NPE_SYS DSPGetSystemSymbolValueInLC("NPE_SYS", DSP_LC_N)
#define DSP_NPE_USR DSPGetSystemSymbolValueInLC("NPE_USR", DSP_LC_N)
#define DSP_NPI_RAM DSPGetSystemSymbolValueInLC("NPI_RAM", DSP_LC_N)
#define DSP_NPI_ROM DSPGetSystemSymbolValueInLC("NPI_ROM", DSP_LC_N)
#define DSP_NPI_SYS DSPGetSystemSymbolValueInLC("NPI_SYS", DSP_LC_N)
#define DSP_NPI_USR DSPGetSystemSymbolValueInLC("NPI_USR", DSP_LC_N)
#define DSP_NXE_RAM DSPGetSystemSymbolValueInLC("NXE_RAM", DSP_LC_N)
#define DSP_NXE_SYS DSPGetSystemSymbolValueInLC("NXE_SYS", DSP_LC_N)
#define DSP_NXE_USR DSPGetSystemSymbolValueInLC("NXE_USR", DSP_LC_N)
#define DSP_NXI_RAM DSPGetSystemSymbolValueInLC("NXI_RAM", DSP_LC_N)
#define DSP_NXI_ROM DSPGetSystemSymbolValueInLC("NXI_ROM", DSP_LC_N)
#define DSP_NXI_SYS DSPGetSystemSymbolValueInLC("NXI_SYS", DSP_LC_N)
#define DSP_NXI_USR DSPGetSystemSymbolValueInLC("NXI_USR", DSP_LC_N)
#define DSP_NYE_RAM DSPGetSystemSymbolValueInLC("NYE_RAM", DSP_LC_N)
#define DSP_NYE_SYS DSPGetSystemSymbolValueInLC("NYE_SYS", DSP_LC_N)
#define DSP_NYE_USR DSPGetSystemSymbolValueInLC("NYE_USR", DSP_LC_N)
#define DSP_NYI_RAM DSPGetSystemSymbolValueInLC("NYI_RAM", DSP_LC_N)
#define DSP_NYI_ROM DSPGetSystemSymbolValueInLC("NYI_ROM", DSP_LC_N)
#define DSP_NYI_SYS DSPGetSystemSymbolValueInLC("NYI_SYS", DSP_LC_N)
#define DSP_NYI_USR DSPGetSystemSymbolValueInLC("NYI_USR", DSP_LC_N)
#define DSP_PHE_RAM DSPGetSystemSymbolValueInLC("PHE_RAM", DSP_LC_N)
#define DSP_PHE_SYS DSPGetSystemSymbolValueInLC("PHE_SYS", DSP_LC_N)
#define DSP_PHE_USR DSPGetSystemSymbolValueInLC("PHE_USR", DSP_LC_N)
#define DSP_PHI_RAM DSPGetSystemSymbolValueInLC("PHI_RAM", DSP_LC_N)
#define DSP_PHI_ROM DSPGetSystemSymbolValueInLC("PHI_ROM", DSP_LC_N)
#define DSP_PHI_SYS DSPGetSystemSymbolValueInLC("PHI_SYS", DSP_LC_N)
#define DSP_PHI_USR DSPGetSystemSymbolValueInLC("PHI_USR", DSP_LC_N)
#define DSP_PLE_RAM DSPGetSystemSymbolValueInLC("PLE_RAM", DSP_LC_N)
#define DSP_PLE_SYS DSPGetSystemSymbolValueInLC("PLE_SYS", DSP_LC_N)
#define DSP_PLE_USR DSPGetSystemSymbolValueInLC("PLE_USR", DSP_LC_N)
#define DSP_PLI_RAM DSPGetSystemSymbolValueInLC("PLI_RAM", DSP_LC_N)
#define DSP_PLI_ROM DSPGetSystemSymbolValueInLC("PLI_ROM", DSP_LC_N)
#define DSP_PLI_SYS DSPGetSystemSymbolValueInLC("PLI_SYS", DSP_LC_N)
#define DSP_PLI_USR DSPGetSystemSymbolValueInLC("PLI_USR", DSP_LC_N)
#define DSP_XHE_RAM DSPGetSystemSymbolValueInLC("XHE_RAM", DSP_LC_N)
#define DSP_XHE_SYS DSPGetSystemSymbolValueInLC("XHE_SYS", DSP_LC_N)
#define DSP_XHE_USR DSPGetSystemSymbolValueInLC("XHE_USR", DSP_LC_N)
#define DSP_XHI_RAM DSPGetSystemSymbolValueInLC("XHI_RAM", DSP_LC_N)
#define DSP_XHI_ROM DSPGetSystemSymbolValueInLC("XHI_ROM", DSP_LC_N)
#define DSP_XHI_SYS DSPGetSystemSymbolValueInLC("XHI_SYS", DSP_LC_N)
#define DSP_XHI_USR DSPGetSystemSymbolValueInLC("XHI_USR", DSP_LC_N)
#define DSP_XLE_RAM DSPGetSystemSymbolValueInLC("XLE_RAM", DSP_LC_N)
#define DSP_XLE_SYS DSPGetSystemSymbolValueInLC("XLE_SYS", DSP_LC_N)
#define DSP_XLE_USR DSPGetSystemSymbolValueInLC("XLE_USR", DSP_LC_N)
#define DSP_XLI_RAM DSPGetSystemSymbolValueInLC("XLI_RAM", DSP_LC_N)
#define DSP_XLI_ROM DSPGetSystemSymbolValueInLC("XLI_ROM", DSP_LC_N)
#define DSP_XLI_SYS DSPGetSystemSymbolValueInLC("XLI_SYS", DSP_LC_N)
#define DSP_XLI_USR DSPGetSystemSymbolValueInLC("XLI_USR", DSP_LC_N)
#define DSP_YHE_RAM DSPGetSystemSymbolValueInLC("YHE_RAM", DSP_LC_N)
#define DSP_YHE_SYS DSPGetSystemSymbolValueInLC("YHE_SYS", DSP_LC_N)
#define DSP_YHE_USR DSPGetSystemSymbolValueInLC("YHE_USR", DSP_LC_N)
#define DSP_YHI_RAM DSPGetSystemSymbolValueInLC("YHI_RAM", DSP_LC_N)
#define DSP_YHI_ROM DSPGetSystemSymbolValueInLC("YHI_ROM", DSP_LC_N)
#define DSP_YHI_SYS DSPGetSystemSymbolValueInLC("YHI_SYS", DSP_LC_N)
#define DSP_YHI_USR DSPGetSystemSymbolValueInLC("YHI_USR", DSP_LC_N)
#define DSP_YLE_RAM DSPGetSystemSymbolValueInLC("YLE_RAM", DSP_LC_N)
#define DSP_YLE_SYS DSPGetSystemSymbolValueInLC("YLE_SYS", DSP_LC_N)
#define DSP_YLE_USR DSPGetSystemSymbolValueInLC("YLE_USR", DSP_LC_N)
#define DSP_YLI_RAM DSPGetSystemSymbolValueInLC("YLI_RAM", DSP_LC_N)
#define DSP_YLI_ROM DSPGetSystemSymbolValueInLC("YLI_ROM", DSP_LC_N)
#define DSP_YLI_SYS DSPGetSystemSymbolValueInLC("YLI_SYS", DSP_LC_N)
#define DSP_YLI_USR DSPGetSystemSymbolValueInLC("YLI_USR", DSP_LC_N)

/***** X SYMBOLS *****/
#define DSP_X_ABORT_A1 DSPGetSystemSymbolValueInLC("X_ABORT_A1", DSP_LC_X)
#define DSP_X_ABORT_DMASTAT DSPGetSystemSymbolValueInLC("X_ABORT_DMASTAT", DSP_LC_X)
#define DSP_X_ABORT_HCR DSPGetSystemSymbolValueInLC("X_ABORT_HCR", DSP_LC_X)
#define DSP_X_ABORT_HSR DSPGetSystemSymbolValueInLC("X_ABORT_HSR", DSP_LC_X)
#define DSP_X_ABORT_M_IO DSPGetSystemSymbolValueInLC("X_ABORT_M_IO", DSP_LC_X)
#define DSP_X_ABORT_RUNSTAT DSPGetSystemSymbolValueInLC("X_ABORT_RUNSTAT", DSP_LC_X)
#define DSP_X_ABORT_R_HMS DSPGetSystemSymbolValueInLC("X_ABORT_R_HMS", DSP_LC_X)
#define DSP_X_ABORT_R_I1 DSPGetSystemSymbolValueInLC("X_ABORT_R_I1", DSP_LC_X)
#define DSP_X_ABORT_R_IO DSPGetSystemSymbolValueInLC("X_ABORT_R_IO", DSP_LC_X)
#define DSP_X_ABORT_SP DSPGetSystemSymbolValueInLC("X_ABORT_SP", DSP_LC_X)
#define DSP_X_ABORT_SR DSPGetSystemSymbolValueInLC("X_ABORT_SR", DSP_LC_X)
#define DSP_X_ABORT_X0 DSPGetSystemSymbolValueInLC("X_ABORT_X0", DSP_LC_X)
#define DSP_X_DMA1_R_M DSPGetSystemSymbolValueInLC("X_DMA1_R_M", DSP_LC_X)
#define DSP_X_DMA1_R_N DSPGetSystemSymbolValueInLC("X_DMA1_R_N", DSP_LC_X)
#define DSP_X_DMA1_R_R DSPGetSystemSymbolValueInLC("X_DMA1_R_R", DSP_LC_X)
#define DSP_X_DMA1_R_S DSPGetSystemSymbolValueInLC("X_DMA1_R_S", DSP_LC_X)
#define DSP_X_DMASTAT DSPGetSystemSymbolValueInLC("X_DMASTAT", DSP_LC_X)
#define DSP_X_DMA_REB DSPGetSystemSymbolValueInLC("X_DMA_REB", DSP_LC_X)
#define DSP_X_DMA_REN DSPGetSystemSymbolValueInLC("X_DMA_REN", DSP_LC_X)
#define DSP_X_DMA_REP DSPGetSystemSymbolValueInLC("X_DMA_REP", DSP_LC_X)
#define DSP_X_DMA_RFB DSPGetSystemSymbolValueInLC("X_DMA_RFB", DSP_LC_X)
#define DSP_X_DMA_R_M DSPGetSystemSymbolValueInLC("X_DMA_R_M", DSP_LC_X)
#define DSP_X_DMA_R_N DSPGetSystemSymbolValueInLC("X_DMA_R_N", DSP_LC_X)
#define DSP_X_DMA_R_R DSPGetSystemSymbolValueInLC("X_DMA_R_R", DSP_LC_X)
#define DSP_X_DMA_R_S DSPGetSystemSymbolValueInLC("X_DMA_R_S", DSP_LC_X)
#define DSP_X_DMA_WEB DSPGetSystemSymbolValueInLC("X_DMA_WEB", DSP_LC_X)
#define DSP_X_DMA_WFB DSPGetSystemSymbolValueInLC("X_DMA_WFB", DSP_LC_X)
#define DSP_X_DMA_WFN DSPGetSystemSymbolValueInLC("X_DMA_WFN", DSP_LC_X)
#define DSP_X_DMA_WFP DSPGetSystemSymbolValueInLC("X_DMA_WFP", DSP_LC_X)
#define DSP_X_DMA_W_M DSPGetSystemSymbolValueInLC("X_DMA_W_M", DSP_LC_X)
#define DSP_X_DMA_W_N DSPGetSystemSymbolValueInLC("X_DMA_W_N", DSP_LC_X)
#define DSP_X_DMA_W_R DSPGetSystemSymbolValueInLC("X_DMA_W_R", DSP_LC_X)
#define DSP_X_DMA_W_S DSPGetSystemSymbolValueInLC("X_DMA_W_S", DSP_LC_X)
#define DSP_X_DMQRP DSPGetSystemSymbolValueInLC("X_DMQRP", DSP_LC_X)
#define DSP_X_DMQWP DSPGetSystemSymbolValueInLC("X_DMQWP", DSP_LC_X)
#define DSP_X_DSPMSG_A1 DSPGetSystemSymbolValueInLC("X_DSPMSG_A1", DSP_LC_X)
#define DSP_X_DSPMSG_B0 DSPGetSystemSymbolValueInLC("X_DSPMSG_B0", DSP_LC_X)
#define DSP_X_DSPMSG_B1 DSPGetSystemSymbolValueInLC("X_DSPMSG_B1", DSP_LC_X)
#define DSP_X_DSPMSG_B2 DSPGetSystemSymbolValueInLC("X_DSPMSG_B2", DSP_LC_X)
#define DSP_X_DSPMSG_M_O DSPGetSystemSymbolValueInLC("X_DSPMSG_M_O", DSP_LC_X)
#define DSP_X_DSPMSG_R_O DSPGetSystemSymbolValueInLC("X_DSPMSG_R_O", DSP_LC_X)
#define DSP_X_DSPMSG_X0 DSPGetSystemSymbolValueInLC("X_DSPMSG_X0", DSP_LC_X)
#define DSP_X_DSPMSG_X1 DSPGetSystemSymbolValueInLC("X_DSPMSG_X1", DSP_LC_X)
#define DSP_X_HMSRP DSPGetSystemSymbolValueInLC("X_HMSRP", DSP_LC_X)
#define DSP_X_HMSWP DSPGetSystemSymbolValueInLC("X_HMSWP", DSP_LC_X)
#define DSP_X_IN_INCR DSPGetSystemSymbolValueInLC("X_IN_INCR", DSP_LC_X)
#define DSP_X_IN_INITIAL_SKIP DSPGetSystemSymbolValueInLC("X_IN_INITIAL_SKIP", DSP_LC_X)
#define DSP_X_I_CHAN_OFFSET DSPGetSystemSymbolValueInLC("X_I_CHAN_OFFSET", DSP_LC_X)
#define DSP_X_I_SFRAME_R DSPGetSystemSymbolValueInLC("X_I_SFRAME_R", DSP_LC_X)
#define DSP_X_I_SFRAME_W DSPGetSystemSymbolValueInLC("X_I_SFRAME_W", DSP_LC_X)
#define DSP_X_LARGS DSPGetSystemSymbolValueInLC("X_LARGS", DSP_LC_X)
#define DSP_X_NCHANS DSPGetSystemSymbolValueInLC("X_NCHANS", DSP_LC_X)
#define DSP_X_NCLIP DSPGetSystemSymbolValueInLC("X_NCLIP", DSP_LC_X)
#define DSP_X_OUT_INITIAL_SKIP DSPGetSystemSymbolValueInLC("X_OUT_INITIAL_SKIP", DSP_LC_X)
#define DSP_X_O_CHAN_COUNT DSPGetSystemSymbolValueInLC("X_O_CHAN_COUNT", DSP_LC_X)
#define DSP_X_O_CHAN_OFFSET DSPGetSystemSymbolValueInLC("X_O_CHAN_OFFSET", DSP_LC_X)
#define DSP_X_O_SFRAME_R DSPGetSystemSymbolValueInLC("X_O_SFRAME_R", DSP_LC_X)
#define DSP_X_O_SFRAME_W DSPGetSystemSymbolValueInLC("X_O_SFRAME_W", DSP_LC_X)
#define DSP_X_O_PADDING DSPGetSystemSymbolValueInLC("X_O_PADDING", DSP_LC_X)
#define DSP_X_O_TICK_SAMPS DSPGetSystemSymbolValueInLC("X_O_TICK_SAMPS", DSP_LC_X)
#define DSP_X_SAVED_A0 DSPGetSystemSymbolValueInLC("X_SAVED_A0", DSP_LC_X)
#define DSP_X_SAVED_A1 DSPGetSystemSymbolValueInLC("X_SAVED_A1", DSP_LC_X)
#define DSP_X_SAVED_A2 DSPGetSystemSymbolValueInLC("X_SAVED_A2", DSP_LC_X)
#define DSP_X_SAVED_B0 DSPGetSystemSymbolValueInLC("X_SAVED_B0", DSP_LC_X)
#define DSP_X_SAVED_B1 DSPGetSystemSymbolValueInLC("X_SAVED_B1", DSP_LC_X)
#define DSP_X_SAVED_B2 DSPGetSystemSymbolValueInLC("X_SAVED_B2", DSP_LC_X)
#define DSP_X_SAVED_HOST_RCV1 DSPGetSystemSymbolValueInLC("X_SAVED_HOST_RCV1", DSP_LC_X)
#define DSP_X_SAVED_HOST_RCV2 DSPGetSystemSymbolValueInLC("X_SAVED_HOST_RCV2", DSP_LC_X)
#define DSP_X_SAVED_HOST_XMT1 DSPGetSystemSymbolValueInLC("X_SAVED_HOST_XMT1", DSP_LC_X)
#define DSP_X_SAVED_HOST_XMT2 DSPGetSystemSymbolValueInLC("X_SAVED_HOST_XMT2", DSP_LC_X)
#define DSP_X_SAVED_M_HMS DSPGetSystemSymbolValueInLC("X_SAVED_M_HMS", DSP_LC_X)
#define DSP_X_SAVED_M_I1 DSPGetSystemSymbolValueInLC("X_SAVED_M_I1", DSP_LC_X)
#define DSP_X_SAVED_M_I2 DSPGetSystemSymbolValueInLC("X_SAVED_M_I2", DSP_LC_X)
#define DSP_X_SAVED_M_O DSPGetSystemSymbolValueInLC("X_SAVED_M_O", DSP_LC_X)
#define DSP_X_SAVED_N_HMS DSPGetSystemSymbolValueInLC("X_SAVED_N_HMS", DSP_LC_X)
#define DSP_X_SAVED_N_I1 DSPGetSystemSymbolValueInLC("X_SAVED_N_I1", DSP_LC_X)
#define DSP_X_SAVED_N_I2 DSPGetSystemSymbolValueInLC("X_SAVED_N_I2", DSP_LC_X)
#define DSP_X_SAVED_N_O DSPGetSystemSymbolValueInLC("X_SAVED_N_O", DSP_LC_X)
#define DSP_X_SAVED_REGISTERS DSPGetSystemSymbolValueInLC("X_SAVED_REGISTERS", DSP_LC_X)
#define DSP_X_SAVED_R_HMS DSPGetSystemSymbolValueInLC("X_SAVED_R_HMS", DSP_LC_X)
#define DSP_X_SAVED_R_I1 DSPGetSystemSymbolValueInLC("X_SAVED_R_I1", DSP_LC_X)
#define DSP_X_SAVED_R_I1_HMLIB DSPGetSystemSymbolValueInLC("X_SAVED_R_I1_HMLIB", DSP_LC_X)
#define DSP_X_SAVED_R_I2 DSPGetSystemSymbolValueInLC("X_SAVED_R_I2", DSP_LC_X)
#define DSP_X_SAVED_R_O DSPGetSystemSymbolValueInLC("X_SAVED_R_O", DSP_LC_X)
#define DSP_X_SAVED_SR DSPGetSystemSymbolValueInLC("X_SAVED_SR", DSP_LC_X)
#define DSP_X_SAVED_X0 DSPGetSystemSymbolValueInLC("X_SAVED_X0", DSP_LC_X)
#define DSP_X_SAVED_X1 DSPGetSystemSymbolValueInLC("X_SAVED_X1", DSP_LC_X)
#define DSP_X_SAVED_Y0 DSPGetSystemSymbolValueInLC("X_SAVED_Y0", DSP_LC_X)
#define DSP_X_SAVED_Y1 DSPGetSystemSymbolValueInLC("X_SAVED_Y1", DSP_LC_X)
#define DSP_X_SCI_COUNT DSPGetSystemSymbolValueInLC("X_SCI_COUNT", DSP_LC_X)
#define DSP_X_SCRATCH1 DSPGetSystemSymbolValueInLC("X_SCRATCH1", DSP_LC_X)
#define DSP_X_SCRATCH2 DSPGetSystemSymbolValueInLC("X_SCRATCH2", DSP_LC_X)
#define DSP_X_SSI_REB DSPGetSystemSymbolValueInLC("X_SSI_REB", DSP_LC_X)
#define DSP_X_SSI_REN DSPGetSystemSymbolValueInLC("X_SSI_REN", DSP_LC_X)
#define DSP_X_SSI_REP DSPGetSystemSymbolValueInLC("X_SSI_REP", DSP_LC_X)
#define DSP_X_SSI_RFB DSPGetSystemSymbolValueInLC("X_SSI_RFB", DSP_LC_X)
#define DSP_X_SSI_SAVED_1 DSPGetSystemSymbolValueInLC("X_SSI_SAVED_1", DSP_LC_X)
#define DSP_X_SSI_SAVED_2 DSPGetSystemSymbolValueInLC("X_SSI_SAVED_2", DSP_LC_X)
#define DSP_X_SSI_SBUFS DSPGetSystemSymbolValueInLC("X_SSI_SBUFS", DSP_LC_X)
#define DSP_X_SSI_SBUFS_GOAL DSPGetSystemSymbolValueInLC("X_SSI_SBUFS_GOAL", DSP_LC_X)
#define DSP_X_START DSPGetSystemSymbolValueInLC("X_START", DSP_LC_X)
#define DSP_X_SYS_CALL_ARG DSPGetSystemSymbolValueInLC("X_SYS_CALL_ARG", DSP_LC_X)
#define DSP_X_TICK DSPGetSystemSymbolValueInLC("X_TICK", DSP_LC_X)
#define DSP_X_TMQRP DSPGetSystemSymbolValueInLC("X_TMQRP", DSP_LC_X)
#define DSP_X_TMQWP DSPGetSystemSymbolValueInLC("X_TMQWP", DSP_LC_X)
#define DSP_X_XHM_R_I1 DSPGetSystemSymbolValueInLC("X_XHM_R_I1", DSP_LC_X)
#define DSP_X_ZERO DSPGetSystemSymbolValueInLC("X_ZERO", DSP_LC_X)

/***** Y SYMBOLS *****/
#define DSP_YB_DMA_R DSPGetSystemSymbolValueInLC("YB_DMA_R", DSP_LC_Y)
#define DSP_YB_DMA_R0 DSPGetSystemSymbolValueInLC("YB_DMA_R0", DSP_LC_Y)
#define DSP_YB_DMA_R2 DSPGetSystemSymbolValueInLC("YB_DMA_R2", DSP_LC_Y)
#define DSP_YB_DMA_W DSPGetSystemSymbolValueInLC("YB_DMA_W", DSP_LC_Y)
#define DSP_YB_DMA_W0 DSPGetSystemSymbolValueInLC("YB_DMA_W0", DSP_LC_Y)
#define DSP_YB_DMA_W2 DSPGetSystemSymbolValueInLC("YB_DMA_W2", DSP_LC_Y)
#define DSP_YB_DMQ DSPGetSystemSymbolValueInLC("YB_DMQ", DSP_LC_Y)
#define DSP_YB_DMQ0 DSPGetSystemSymbolValueInLC("YB_DMQ0", DSP_LC_Y)
#define DSP_YB_HMS DSPGetSystemSymbolValueInLC("YB_HMS", DSP_LC_Y)
#define DSP_YB_HMS0 DSPGetSystemSymbolValueInLC("YB_HMS0", DSP_LC_Y)
#define DSP_YB_TMQ DSPGetSystemSymbolValueInLC("YB_TMQ", DSP_LC_Y)
#define DSP_YB_TMQ0 DSPGetSystemSymbolValueInLC("YB_TMQ0", DSP_LC_Y)
#define DSP_YB_TMQ2 DSPGetSystemSymbolValueInLC("YB_TMQ2", DSP_LC_Y)
#define DSP_Y_DEVSTAT DSPGetSystemSymbolValueInLC("Y_DEVSTAT", DSP_LC_Y)
#define DSP_Y_RUNSTAT DSPGetSystemSymbolValueInLC("Y_RUNSTAT", DSP_LC_Y)
#define DSP_Y_TICK DSPGetSystemSymbolValueInLC("Y_TICK", DSP_LC_Y)
#define DSP_Y_TINC DSPGetSystemSymbolValueInLC("Y_TINC", DSP_LC_Y)
#define DSP_Y_ZERO DSPGetSystemSymbolValueInLC("Y_ZERO", DSP_LC_Y)

/***** L SYMBOLS *****/
#define DSP_L_LARGS_DEVSTAT DSPGetSystemSymbolValueInLC("L_LARGS_DEVSTAT", DSP_LC_L)
#define DSP_L_STATUS DSPGetSystemSymbolValueInLC("L_STATUS", DSP_LC_L)
#define DSP_L_TICK DSPGetSystemSymbolValueInLC("L_TICK", DSP_LC_L)
#define DSP_L_TINC DSPGetSystemSymbolValueInLC("L_TINC", DSP_LC_L)
#define DSP_L_ZERO DSPGetSystemSymbolValueInLC("L_ZERO", DSP_LC_L)
#endif
