;;  Copyright 1990 NeXT Computer, Inc.  All rights reserved.
;;  Author - Julius Smith
;;
;;  Modification history
;;  --------------------
;;  06/07/89/mm - initial file created from unoise.asm
;;
;;------------------------------ DOCUMENTATION ---------------------------
;;  NAME
;;      snoise (UG macro) - Sampled (1 per tick) uniform random numbers
;;
;;  SYNOPSIS
;;      snoise pf,ic,sout,aout0,seed0
;;
;;  MACRO ARGUMENTS
;;      pf    = global label prefix (any text unique to invoking macro)
;;      ic    = instance count (such that pf\_unoise_\ic\_ is globally unique)
;;      sout  = output vector memory space ('x' or 'y')
;;      aout0 = initial output vector memory address
;;      seed0 = initial state of random number generator (becomes last number)
;;
;;  DSP MEMORY ARGUMENTS
;;      Access         Description              Initialization
;;      ------         -----------              --------------
;;      x:(R_X)+       Current output address   aout0
;;      y:(R_Y)+       Current state            seed0
;;
;;  DESCRIPTION
;;      The snoise unit-generator computes uniform pseudo-white noise
;;      using the linear congruential method for random number generation
;;      (reference: Knuth, volume II of The Art of Computer Programming).
;;      The multiplier used has not been tested for quality.  This is the 
;;      same as unoise.asm, but only computes one new number per tick.
;;      
;;  DSPWRAP ARGUMENT INFO
;;      snoise (prefix)pf,(instance)ic,(dspace)sout,(output)aout,seed
;;
;;  MAXIMUM EXECUTION TIME
;;      56 DSP clock cycles for one "tick" which equals 16 audio samples.
;;
;;  MINIMUM EXECUTION TIME
;;      Same as maximum.
;;
;;  CALLING PROGRAM TEMPLATE
;;      include 'music_macros'        ; utility macros
;;      beg_orch 'tunoise'            ; begin orchestra main program
;;           new_yeb outvec,I_NTICK,0 ; Allocate output vector
;;           beg_orcl                 ; begin orchestra loop
;;                snoise orch,1,y,outvec,0 ; Macro invocation
;;           end_orcl                 ; end of orchestra loop
;;      end_orch 'tunoise'            ; end of orchestra main program
;;
;;  SOURCE
;;      /usr/local/lib/dsp/ugsrc/snoise.asm
;;
;;  ALU REGISTER USE
;;      X1 = multiplier
;;      X0 = previous random number
;;       A = offset, then (garbage,new_random_number)
;;       B = 48 bits containing (0,offset)
;;
snoise_offset set 1                     ; value of offset (any positive word)

snoise    macro pf,ic,sout,aout0,seed0
          new_xarg pf\_snoise_\ic\_,aout,aout0    ; output address arg
          new_yarg pf\_snoise_\ic\_,seed,seed0    ; random number state
          clr B x:(R_X)+,R_O            ; output address to R_O
          move #>snoise_offset*2,B0     ; (48-bit) offset, times 2, to B
          tfr B,A y:(R_Y),X0            ; offset to A, current seed to X0
          move #5609937,X1              ; pick a number = 1 mod 4
          mac X0,X1,A                   ; make A0 valid
          asr A                         ; now A0 contains unsigned X0*X1 LSP
          do #I_NTICK,pf\_snoise_\ic\_tickloop
               move A0,sout:(R_O)+
pf\_snoise_\ic\_tickloop    
          move A0,y:(R_Y)+              ; update seed
     endm


