/*
  $Id$
  Defined In: The MusicKit

  Description: 
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:18  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  daj/04/23/90 - Created from _musickit.h 
  daj/01/14/91 - Added _MK_substring
*/

typedef enum __MKToken {   
	 _MK_undef = 0400,  
	 _MK_param = ((int)MK_waveTable + 1), /* 285 */
	 _MK_objDefStart,
	 _MK_typedVar,
	 _MK_untypedVar,
	 _MK_uMinus,
	 _MK_intVarDecl,
	 _MK_doubleVarDecl,
	 _MK_stringVarDecl,
	 _MK_varDecl,
	 _MK_envVarDecl,
	 _MK_waveVarDecl,
	 _MK_objVarDecl,
	 _MK_envelopeDecl,
	 _MK_waveTableDecl,
	 _MK_objectDecl,
	 _MK_include,
	 _MK_print,
	 _MK_time,
	 _MK_part,
	 _MK_partInstance,
	 _MK_scoreInstance,
	 _MK_begin,
	 _MK_end,
	 _MK_comment,
	 _MK_endComment,
	 _MK_to,
	 _MK_tune,
	 _MK_ok,
	 _MK_noteTagRange,
	 _MK_dB,
	 _MK_ran,
	 _MK_dataFile,
	 _MK_xEnvValue,
	 _MK_yEnvValue,
	 _MK_smoothingEnvValue,
	 _MK_hNumWaveValue,
	 _MK_ampWaveValue,
	 _MK_phaseWaveValue,
	 _MK_lookupEnv,
	 _MK_info,
	 _MK_putGlobal,
	 _MK_getGlobal,
	 _MK_seed,
	 _MK_ranSeed,
	 _MK_LEQ,
	 _MK_GEQ,
	 _MK_EQU,
	 _MK_NEQ,
	 _MK_OR,
	 _MK_AND,
	 _MK_repeat,
	 _MK_if,
	 _MK_else,
	 _MK_while,
	 _MK_do,
	 _MK_substring,
	 /* End marker */
	 _MK_highestToken
    } _MKToken;


/* MKTokens */
#define _MK_VALIDTOKEN(_x) \
   ((((int)(_x))>=((int)_MK_undef))&&(((int)(_x))<((int)_MK_highestToken)))

/* This may be used to write names of _MKTokens, MKDataTypes,
   MKMidiPars and MKNoteTypes. */
extern const char * _MKTokName(int tok);
extern const char * _MKTokNameNoCheck(int tok);