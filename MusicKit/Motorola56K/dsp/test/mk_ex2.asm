; mk_ex2.asm - Test program for unit generator macro oscgafi
;
; Generate a test sinusoid.  
;
; Usage:
;	asm56000 -A -B -L -OS,SO -I/usr/local/lib/dsp/smsrc/ mk_ex2
;	open /LocalDeveloper/Apps/Bug56.app
;	<File / Load & erase symbols> mk_ex2.lod
;	<SSTEP on main control panel>
;	<STEP on single-step panel>
;	...
;	<or RUN on main control panel - a breakpoint is provided below>
;
; At the label TICK_LOOP, you may wish to step over the subroutine call which
; carries out "system updates".  This can be done by adding 2 to the address
; in the main Bug56 control panel, or you can type <command>R and write two
; NOPs in place of the subroutine call.
;	
; If you do run the system updates, after a number of TICK_LOOP executions,
; you can view the sound waveform in the sound output buffers of the system.
; A breakpoint is set below to go off after 256 samples are generated, so you
; can hit the "Run" button on the main Bug56 control panel to generate
; 256 samples of output.  This exactly fills both DMA output buffers in the 
; DSP system.  The buffers each contain 256 samples in stereo.
; Note that every other sample is zero because the output buffer
; is stereo, and we are only sending data to channel A.
;
; When Bug56 halts at the breakpoint, open a Y memory viewer and set the 
; lower limit to y:YB_DMA_W.  The other buffer follows right after it
; and has its own label YB_DMA_W2. You should see samples of the 
; output waveform, right-shifted 8 bits.  (The 16-bit samples must be
; right-justified in the DMA buffers.)  This scaling happens at the same 
; time DMA requests go out.  If you look at the DMA buffer BEFORE DMA 
; request time, the samples will be left-justified (i.e., not scaled).
;
mk_ex2  ident 0,0		; version, revision (arbitrary)
        include 'sys_xdefs.asm' 
	include 'config_standalone'
;*	define nolist 'list'	; get absolutely everything into listing file
	include 'music_macros'	; utility macros

nsamps	set 256			; number of samples to compute (at most NB_DMA_W/4!)
nsintab equ 256			; wavetable length (sine table in ROM)
srate	equ 44100.0		; samples per second
amp	equ 0.5			; carrier amplitude
inc	equ 1.1			; table increment: Freq = inc*srate/nsintab
frqscl	equ 1.0/256.0		; inc scaler, to allow increments up to 256
incscl	equ 256.0/@pow(2.,23.)	; inc scaler, to allow increments up to 256

	beg_orch 'mk_ex2'	; standard startup for orchestras

	new_xib xsig,I_NTICK,0		; allocate waveform vector
	new_xib xamp,I_NTICK,amp 	; allocate amplitude vector
	new_xib xfrq,I_NTICK,inc*frqscl ; allocate increment vector

	beg_orcl
		nop_sep 3	; nop's to help find boundary
;;		oscgafi pf,ic,sout,aout0,sina,aina0,sinf,ainf0,inc0,
;;			phs0h,phs0l,stab,atab0,mtab0
		oscgafi orch,1,x,xsig,x,xamp,x,xfrq,incscl,0,0,y,YLI_SIN,$FF
		nop_sep 3	   	; nop's to help find boundary
		out2sumbug56 orch,1,x,xsig,1.0,0 ; Output signal to DAC channel A
		nop_sep 3	   	; nop's to help find boundary
		break_on_sample nsamps	; stop after nsamps samples (misc.asm)
	end_orcl
finish	end_orch 'mk_ex2'



