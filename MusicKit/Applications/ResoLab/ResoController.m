
/* Generated by Interface Builder */

/* ResoController.m by Perry R. Cook
Implementation of Zeros, as well as data storage for poles and zeros added by Daniel Culbert
*/

#import "ResoController.h"
#import "SpectrumView.h"
#import "ZPlaneView.h"
#import <appkit/appkit.h>
#import <musickit/musickit.h>
#import "SourceFilterIns.h"
#import "Xforms.h"
#import "Z3DPlaneView.h"
#import <math.h>

#define PI 3.141592654782
#define TWO_PI 6.283185309564
#define SRATE 22050

double freqs[200],amps[200],phases[200];
boolean_t we_singin = FALSE;

@implementation ResoController

/*DJC:  Initialize data storage. Note that ideally, these poles and zeros should be implmented as 
objects, but there were few enough of them that I chose to use an array structured for
easy loading of new values from the filterFields
*/

+ new
{
	int i;
	self = [super new];
	
	theP_Z.cen_res[0] = 1000;
	theP_Z.cen_res[1] = 0.95;
	theP_Z.cen_res[2] = 2000;
	theP_Z.cen_res[3] = 0.95;
	theP_Z.cen_res[4] = 3000;
	theP_Z.cen_res[5] = 0.95;
	theP_Z.num_poles = 6;
	for(i = ZEROSBEGIN * 2; i < 12; i++) theP_Z.cen_res[i] = 0;
	theXform = [Xforms new];
	return self;
}

- init
{
    [self changeFilter: filterFields];
    return self;
}

- setButton:anObject
{
    button = anObject;
    return self;
}

- setPoleGains:anObject
{
    poleGains = anObject;
    return self;
}

- setLinkSpectrum:anObject
{
    linkSpectrum = anObject;
    return self;
}

- setPulseLevel:anObject
{
    pulseLevel = anObject;
    return self;
}

- setNoiseLevel:anObject
{
    noiseLevel = anObject;
    return self;
}

- setRandLevel:anObject
{
    randLevel = anObject;
    return self;
}

- setPerLevel:anObject
{
    perLevel = anObject;
    return self;
}

- setVibField:anObject
{
    vibField = anObject;
    return self;
}

- setNumHarmonics:anObject
{
    numHarmonics = anObject;
    return self;
}

- setFilterFields:anObject
{
    filterFields = anObject;
    return self;
}

- setFilterZFields:anObject
{
    filterZFields = anObject;
    return self;
}

- setPitchField:anObject
{
    pitchField = anObject;
    return self;
}

- setSourceFader:anObject
{
    sourceFader = anObject;
    return self;
}

- setMySpectrum:anObject
{
    mySpectrum = anObject;
    return self;
}

- setMyZPlane:anObject
{
    myZPlane = anObject;
    return self;
}

- setMy3DZPlane:anObject
{
	my3DZPlane = anObject;
	return self;
}

- makeVowel:sender
{
    char shapes[10][3] = 	{{"ee"},
    			 	{"ih"},
    			 	{"eh"},
    			 	{"aa"},
    			 	{"uh"},
				{"ah"},
    			 	{"aw"},
    			 	{"uu"},
    			 	{"oo"},
    			 	{"rr"}};
    float formants[10][3] = 	{{270,2290,3010},
				{390,1990,2550},
				{530,1840,2480},
				{660,1720,2410},
				{520,1190,2390},
				{730,1090,2440},
				{570,840,2410},
				{440,1020,2240},
				{300,870,2240},
				{490,1350,1690}};
    int i,j;
    char name[3];
    for (i=0;i<10;i++)	{
        strcpy(name,[sender title]);
	if (!strcmp(name,shapes[i]))	{
	    for (j=0;j<3;j++)	{
	        [[filterFields cellAt: j*2 : 0] setFloatValue: formants[i][j]];
		[[filterFields cellAt: j*2 + 1 : 0] setFloatValue: 0.97];
	        [[filterZFields cellAt: j*2 : 0] setFloatValue: 0.0];
		[[filterZFields cellAt: j*2 + 1 : 0] setFloatValue: 0.0];
	    }
	    i = 10;
	}
    }
    [self changeFilter: filterFields];
	return self;
}

- makeNoise:sender
{
    int i;

    if ([sender state] == 1)	{
        theOrch = [Orchestra new];          
        [theOrch setSamplingRate: 22050.0];
	we_singin = TRUE;
        theNote = [Note new];			
        [theNote setNoteType:MK_noteOn]; 	
        [theNote setNoteTag:MKNoteTag()];      
	theNoteUpdate = [Note new];
        [theNoteUpdate setNoteType:MK_noteUpdate]; 
        [theNoteUpdate setNoteTag:[theNote noteTag]]; 
        [Orchestra setTimed:NO];             
        if (![theOrch open]) {               
	fprintf(stderr,"Can't open DSP. Perhaps some other process has it.\n");
	    exit(1);
        }
        theIns = [SynthInstrument new];      
        [theIns setSynthPatchClass: [SourceFilterIns class]];   
        [theIns setSynthPatchCount:1];	
        [Conductor setFinishWhenEmpty:NO];
        [theOrch run];				
        [Conductor startPerformance];    
	[Conductor adjustTime];	
        [theNote setPar:MK_lowestFreq toDouble: 50.0];   
        [theNote setPar:MK_waveLen toInt: 1024];  
//        [theNote setPar:MK_waveform toWaveTable: theWave];
	[[theIns noteReceiver] receiveNote:theNote]; 
	[self changeHarmonics: nil];
	[self changeFilter: filterFields]; 
        [self changeSource: nil];
        [self changeMod: nil];
        [self changePitch:  pitchField];
	[Orchestra flushTimedMessages];      
    }
    else	{
        we_singin = FALSE;
        [Conductor adjustTime];               
        [Conductor finishPerformance];       
	[theNoteUpdate free];
	[theNote free];
	[theOrch close];
	[theOrch free];
    }
    return self;
}

- changeSource:sender
{
    int		RESO_sourceFader = [[Note class] parName: "RESO_sourceFader"];
    int		RESO_oscLevel = [[Note class] parName: "RESO_oscLevel"];
    int		RESO_noiseLevel = [[Note class] parName: "RESO_noiseLevel"];
    if (we_singin)	{
        [Conductor adjustTime];             
        [theNoteUpdate setPar:RESO_sourceFader toDouble:
			[sourceFader doubleValue]];  
        [theNoteUpdate setPar:RESO_oscLevel toDouble: 
			[pulseLevel doubleValue]];  
        [theNoteUpdate setPar:RESO_noiseLevel toDouble: 
			[noiseLevel doubleValue]];  
        [[theIns noteReceiver] receiveNote:theNoteUpdate];
        [Orchestra flushTimedMessages];
    }
    return self;
}

- changeMod:sender
{
    double temp;
    if (we_singin)	{
        [Conductor adjustTime];             
        temp = [vibField doubleValue];
	[theNoteUpdate setPar:MK_svibFreq0 toDouble: temp];  
        [theNoteUpdate setPar:MK_svibFreq1 toDouble: temp];  
        temp = [perLevel doubleValue];
	[theNoteUpdate setPar:MK_svibAmp0 toDouble: temp];  
        [theNoteUpdate setPar:MK_svibAmp1 toDouble: temp];  
        [theNoteUpdate setPar:MK_rvibAmp toDouble: [randLevel doubleValue]];  
        [[theIns noteReceiver] receiveNote:theNoteUpdate];
        [Orchestra flushTimedMessages];
    }
    return self;
}

- changeHarmonics:sender
{
    int i;
    float num_harms;
    int 	RESO_numHarmonics = [Note parName:"RESO_numHarmonics"];

    if (we_singin)	{
        num_harms = [numHarmonics floatValue];
	if (num_harms>199) {
	    num_harms = 199;
	    [numHarmonics setIntValue: 199];
	}
	if (num_harms<1) {
	    num_harms = 1;
	    [numHarmonics setIntValue: 1];
	}

        [theNoteUpdate setPar:MK_lowestFreq toDouble: 50.0];   
        [theNoteUpdate setPar:MK_waveLen toInt: 1024];  
        [theNoteUpdate setPar:RESO_numHarmonics toInt: num_harms];  
        [[theIns noteReceiver] receiveNote:theNoteUpdate];
        [Orchestra flushTimedMessages];
    }
    return self;
}

- changePitch:sender
{
    if (we_singin)	{
        [theNoteUpdate setPar:MK_freq0 toDouble:
			[pitchField doubleValue]];  
        [theNoteUpdate setPar:MK_freq1 toDouble:
			[pitchField doubleValue]];  
        [theNoteUpdate setPar:MK_freq toDouble: [pitchField doubleValue]];  
        [[theIns noteReceiver] receiveNote:theNoteUpdate];
        [Orchestra flushTimedMessages];
	[self changeMod: nil];
    }
    return self;
}


- bumpFilter:sender
{
    [self changeFilter:filterFields];
    return self;
}

- changeFilter:sender
{
    register int i;
    register int offset = 0;
    
    if (sender == filterZFields) offset = ZEROSBEGIN * 2;
    for (i=0;i<6;i++)	{
        theP_Z.cen_res[i + offset] = [[sender cellAt: i : 0] floatValue];
    }
    [myZPlane display];
    [self update];
    
    return self;
}

/* update: DJC: added ZEROS */
- update
{
    int i,j;
    float f[256],locs[3],gains[3];
    float input = 1.0,output = 0.0,power=0.0;
    float c[6],xc[6],inZ1=0.0,outZ[6]={0.0,0.0,0.0,0.0,0.0,0.0};
    float radius1,angle1,radius2,angle2,radius3,angle3;
    double a[4],b[4],d[4],e[4],gain[4] = {1.99,1.99,1.99,1.99};
    int		RESO_filt1pr = [[Note class] parName:"RESO_filt1pr"],
    		RESO_filt1pf = [[Note class] parName:"RESO_filt1pf"],
    		RESO_filt1Gain = [[Note class] parName:"RESO_filt1Gain"],
    		RESO_filt2pr = [[Note class] parName:"RESO_filt2pr"],
    		RESO_filt2pf = [[Note class] parName:"RESO_filt2pf"],
    		RESO_filt2Gain = [[Note class] parName:"RESO_filt2Gain"],
    		RESO_filt3pr = [[Note class] parName:"RESO_filt3pr"],
    		RESO_filt3pf = [[Note class] parName:"RESO_filt3pf"],
    		RESO_filt3Gain = [[Note class] parName:"RESO_filt3Gain"],
		
                 RESO_filt1zr = [[Note class] parName:"RESO_filt1zr"],
    		RESO_filt1zf = [[Note class] parName:"RESO_filt1zf"],
    		RESO_filt2zr = [[Note class] parName:"RESO_filt2zr"],
    		RESO_filt2zf = [[Note class] parName:"RESO_filt2zf"],
    		RESO_filt3zr = [[Note class] parName:"RESO_filt3zr"],
    		RESO_filt3zf = [[Note class] parName:"RESO_filt3zf"];


    for (i=0;i<6;i++)	{
         [[filterZFields cellAt: i : 0] setFloatValue: theP_Z.cen_res[i + ZEROSBEGIN * 2]]; 
        [[filterFields cellAt: i : 0] setFloatValue: theP_Z.cen_res[i]];
    }
    
    
    angle1 = theP_Z.cen_res[0] * TWO_PI / SRATE;
    radius1 = theP_Z.cen_res[1];
    angle2 = theP_Z.cen_res[2] * TWO_PI / SRATE;
    radius2 = theP_Z.cen_res[3];
    angle3 = theP_Z.cen_res[4] * TWO_PI / SRATE;
    radius3 = theP_Z.cen_res[5];	
    a[1] = -2.0 * cos(angle1) * radius1;
    b[1] = radius1 * radius1;
    a[2] = -2.0 * cos(angle2) * radius2;
    b[2] = radius2 * radius2;
    a[3] = -2.0 * cos(angle3) * radius3;
    b[3] = radius3 * radius3;

    c[0] = a[1] + a[2] + a[3];
    c[1] = b[1] + b[2] +  b[3] + a[1] * a[2] + a[2] * a[3] + a[1] * a[3];
    c[2] = a[2] * b[1] + b[2] * a[1] + a[3] * b[1] + a[3] * b[2] + 
    			a[1] * a[2] * a[3] + b[3] * a[1] + b[3] * a[2];
    c[3] = b[2] * b[1] + a[3] * a[2] * b[1] + a[3] * b[2] * a[1] + 
    			b[3] * b[1] + b[3] * b[2] + b[3] * a[1] * a[2];
    c[4] = (a[2] * b[1] + b[2] * a[1]) * b[3] + a[3] * b[2] * b[1];
    c[5] = b[3] * b[2] * b[1];

    angle1 = theP_Z.cen_res[6] * TWO_PI / SRATE;
    radius1 = theP_Z.cen_res[7];
    angle2 = theP_Z.cen_res[8] * TWO_PI / SRATE;
    radius2 = theP_Z.cen_res[9];
    angle3 = theP_Z.cen_res[10] * TWO_PI / SRATE;
    radius3 = theP_Z.cen_res[11];	
    d[1] = -2.0 * cos(angle1) * radius1;
    e[1] = radius1 * radius1;
    d[2] = -2.0 * cos(angle2) * radius2;
    e[2] = radius2 * radius2;
    d[3] = -2.0 * cos(angle3) * radius3;
    e[3] = radius3 * radius3;

    xc[0] = d[1] + d[2] + d[3];
    xc[1] = e[1] + e[2] +  e[3] + d[1] * d[2] + d[2] * d[3] + d[1] * d[3];
    xc[2] = d[2] * e[1] + e[2] * d[1] + d[3] * e[1] + d[3] * e[2] + 
    			d[1] * d[2] * d[3] + e[3] * d[1] + e[3] * d[2];
    xc[3] = e[2] * e[1] + d[3] * d[2] * e[1] + d[3] * e[2] * d[1] + 
    			e[3] * e[1] + e[3] * e[2] + e[3] * d[1] * d[2];
    xc[4] = (d[2] * e[1] + e[2] * d[1]) * e[3] + d[3] * e[2] * e[1];
    xc[5] = e[3] * e[2] * e[1];
    
    for (j=0;j<256;j++)	{
	outZ[5] = outZ[4];
        outZ[4] = outZ[3];
	outZ[3] = outZ[2];
        outZ[2] = outZ[1];
        outZ[1] = outZ[0];
        outZ[0] = output;
        output = input;
        for (i=0;i<6;i++)	{
    	    output -= c[i] * outZ[i];
        }
	if ( j < 7 && j > 0)  output  += xc[j-1];
	f[j] = output;
	power += output*output;
	input = 0.0;
    }
    
    /*
    [theXform freqRespData: [self data] Array:f Size: 128];
    [theXform zeroPad: f From: 128  To: 256];
    */
    if (![linkSpectrum state]) {
        [mySpectrum displayData: 4 array: f];
	[mySpectrum getPeaks: 128 array: f numPeaks: 3 locs: locs gains: gains];
	[[poleGains cellAt: 0 : 0] setFloatValue: gains[0]];
	[[poleGains cellAt: 1 : 0] setFloatValue: pow(10.0,3.0 * ((double) gains[1] - 1.0))];
	[[poleGains cellAt: 2 : 0] setFloatValue: pow(10.0,3.0 * ((double) gains[2] - 1.0))];
    }
    power = pow(power,0.136);
    if (we_singin)	{
	[Conductor adjustTime];             

        gain[1] = 1.0 / (power);
        gain[2] = 1.0 / (power);
        gain[3] = 1.0 / (power);

	[theNoteUpdate setPar:RESO_filt1pr toDouble: (double) theP_Z.cen_res[1]];  
        [theNoteUpdate setPar:RESO_filt1pf toDouble: (double) theP_Z.cen_res[0]];  
        [theNoteUpdate setPar:RESO_filt2pr toDouble: (double) theP_Z.cen_res[3]];  
        [theNoteUpdate setPar:RESO_filt2pf toDouble: (double) theP_Z.cen_res[2]];  
        [theNoteUpdate setPar:RESO_filt3pr toDouble: (double) theP_Z.cen_res[5]];  
        [theNoteUpdate setPar:RESO_filt3pf toDouble: (double) theP_Z.cen_res[4]];  
	 
	[theNoteUpdate setPar:RESO_filt1zr toDouble: (double) theP_Z.cen_res[7]];  
        [theNoteUpdate setPar:RESO_filt1zf toDouble: (double) theP_Z.cen_res[6]];  
        [theNoteUpdate setPar:RESO_filt2zr toDouble: (double) theP_Z.cen_res[9]];  
        [theNoteUpdate setPar:RESO_filt2zf toDouble: (double) theP_Z.cen_res[8]];  
        [theNoteUpdate setPar:RESO_filt2zr toDouble: (double) theP_Z.cen_res[11]];  
        [theNoteUpdate setPar:RESO_filt3zf toDouble: (double) theP_Z.cen_res[10]];  

        [theNoteUpdate setPar:RESO_filt1Gain toDouble: gain[1]];
        [theNoteUpdate setPar:RESO_filt2Gain toDouble: gain[2]];
        [theNoteUpdate setPar:RESO_filt3Gain toDouble: gain[3]];

        [[theIns noteReceiver] receiveNote:theNoteUpdate];

        [Orchestra flushTimedMessages];
    }
    return self;
}


/* DJC: extra methods to support ZPlane and 3DPlane */
- (P_ZRec *) data
{
	return &theP_Z;
}

- xform
{
	return theXform;
}

- graph3D:sender
{
	[my3DZPlane setPoles: &theP_Z];
 	[my3DZPlane display];
	return self;
}

@end
