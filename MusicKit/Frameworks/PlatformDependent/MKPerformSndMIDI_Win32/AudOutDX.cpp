//////////////////////////////////////////////////////////////////////////////
// 
// CAudOutDX - DirectX implementation of CAudOut
//
// SKoT McDonald / Vellocet
// skot@vellocet.ii.net
// (c) 1999 Vellocet 
// All rights reserved.
//
// No good for emulated DirectX at the moment.
//
// Last change: 14 July 1999
//
//////////////////////////////////////////////////////////////////////////////

#include "stdafx.h"
#include <process.h>
#include "audoutdx.h"


//////////////////////////////////////////////////////////////////////////////
// @CAudOutDX()
//
// Parameters:
//
// Remarks:
//
// DirectX notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

CAudOutDX::CAudOutDX() : CAudOut()
{
  m_dwMaxDS       = maxDSDev;  
  m_dwMode        = CAudOut::directX;
  m_dwNumDev      = 0;
  m_pDSBuffer     = NULL;
  m_pDS           = (LPDIRECTSOUND) 5;
  m_pDSNotify     = NULL;
  m_DSPosNotify   = NULL;
  m_pGUID         = NULL;
  m_ppchDSDesc    = NULL;
  m_ppchDSModule  = NULL;
  m_dsbe          = NULL;
  m_hWnd          = NULL;
}

//////////////////////////////////////////////////////////////////////////////
// @~CAudOutDX()
//
// Parameters:
//
// Remarks:
//
// DirectX notes:
//
// Returns:
//   True if all is well
//   False if the device is actively playing.
//////////////////////////////////////////////////////////////////////////////

CAudOutDX::~CAudOutDX()
{
  FreeMem();
  FreeBuffers();
}

//////////////////////////////////////////////////////////////////////////////
// @FreeMem()
//
// Parameters:
//
// Remarks:
//
// DirectX notes:
//
// Returns:
//   True if all is well
//   False if the device is actively playing.
//////////////////////////////////////////////////////////////////////////////

bool CAudOutDX::FreeMem(void)
{
  m_err = err_none;

  #ifdef _DEBUG
  m_errstr = "CAudOutDX::FreeMem() ";
  #endif

  if (m_bActive)
    m_err = err_notWhileActive;
  else
  {
    DWORD i;
    if (m_pGUID)
    {
      for (i = 0; i < m_dwNumDev; i++)
        delete m_pGUID[i];
      delete [] m_pGUID;
      m_pGUID = NULL;
    }
    if (m_ppchDSDesc)
    {
      for (i = 0; i < m_dwNumDev; i++)
        delete [] m_ppchDSDesc[i];
      delete [] m_ppchDSDesc;
      m_ppchDSDesc = NULL;
    }
    if (m_ppchDSModule)
    {
      for (i = 0; i < m_dwNumDev; i++)
        delete [] m_ppchDSModule[i];
      delete [] m_ppchDSModule;
      m_ppchDSModule = NULL;
    }
  }
  return (m_err == err_none);
}

//////////////////////////////////////////////////////////////////////////////
// @Initialise()
//
// Parameters:
//   GenAudio - Function called by CAudOut objects when new audio data needs 
//          to be generated.
//   dwGenAudioData - User information to be passed to GenAudio, such as a 
//          pointer to a synthesis object.
//
// Remarks:
//
// DirectX notes:
//
// Returns: False if an error occured during initialisation, true otherwise.
//   m_err is set appropriately on errors.
//////////////////////////////////////////////////////////////////////////////

bool CAudOutDX::Initialise (void (*GenAudio)(float**, DWORD, DWORD, DWORD), 
                            DWORD dwGenAudioData)
{
#ifdef _DEBUG
  if (m_bInit)
  {
    m_errstr = "CAudOutDX::Initialise() ";
    m_err = err_alreadyInit;
    return false;
  }
#endif

  if (!CAudOut::Initialise(GenAudio, dwGenAudioData))
    return false;

  m_err   = err_none;
  m_bInit = false;

  #ifdef _DEBUG
  m_errstr = "CAudOutDX::Initialise() ";
  #endif

  if (!FreeMem())
    return false;

  if ((m_pGUID = new LPGUID[m_dwMaxDS]) == NULL)
    m_err = err_badAlloc;
  else
    memset(m_pGUID, 0, sizeof (LPGUID) * m_dwMaxDS);

  if ((m_ppchDSDesc = new char*[m_dwMaxDS]) == NULL)
    m_err = err_badAlloc;
  else
    memset(m_ppchDSDesc,0,sizeof(char*) * m_dwMaxDS);

  if ((m_ppchDSModule = new char*[m_dwMaxDS]) == NULL)
    m_err = err_badAlloc;
  else
    memset(m_ppchDSModule,0,sizeof(char*) * m_dwMaxDS);

  if ((m_dsbe = new HANDLE[CAudOut::maxBuffers]) == NULL)
    m_err = err_badAlloc;
  else
    memset(m_dsbe, 0, sizeof(HANDLE) * CAudOut::maxBuffers);

  if (m_err == err_none)
  {
    GetDSSystemCaps();
    m_bInit = AllocateBuffers(m_dwNumBuffers, m_dwNumSamples);
  }
  else
    FreeMem();

  return (m_err == err_none);
}

//////////////////////////////////////////////////////////////////////////////
// @AllocateBuffers()
//
// Parameters:
//   dwNumBuffers - The number of sound buffers queued in advance of playback.
//   dwNumSamples - The length, in samples, of each buffer.
//
// Remarks: To minimise latency, reduce the size and number of buffers to a
//   minimum. For more stable playback, increase. Generally at least 3 buffers
//   are a good idea, meaning one buffer is queued, one is being played back,
//   and one buffer is being generated by the host application. By default the
//   class has 4 buffers, providing a little more stability in a multi-process
//   context switching enviroment.
//
// DirectX notes: Allocates the playback position notification array.
//
// Returns: False if an error occured during initialisation, true otherwise.
//   m_err is set appropriately on errors.
//////////////////////////////////////////////////////////////////////////////

bool CAudOutDX::AllocateBuffers(DWORD dwNumBuffers, DWORD dwNumSamples)
{
  m_err = err_none;

  if (!FreeBuffers())
    return false;

  if (!CAudOut::AllocateBuffers(dwNumBuffers, dwNumSamples))
    return false;

  #ifdef _DEBUG
  m_errstr = "CAudOutDX::AllocateBuffers()";
  #endif

  m_DSPosNotify  = new DSBPOSITIONNOTIFY[m_dwNumBuffers];

  if (!m_DSPosNotify)
    m_err = err_badAlloc;
  else
    memset(m_DSPosNotify, 0, sizeof(DSBPOSITIONNOTIFY) * m_dwNumBuffers);

  if (m_err != err_none)
  {
    FreeBuffers();
  }
  return (m_err == err_none);
}

//////////////////////////////////////////////////////////////////////////////
// @FreeBuffers()
//
// Parameters:
//
// Remarks:
//
// DirectX notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

bool CAudOutDX::FreeBuffers(void)
{
  #ifdef _DEBUG
  m_errstr = "CAudOutDX::FreeBuffers() ";
  #endif

  if (m_DSPosNotify)
  {
    delete m_DSPosNotify;
    m_DSPosNotify = NULL;
  }
  return CAudOut::FreeBuffers();
}

//////////////////////////////////////////////////////////////////////////////
// @ProcessDXReturn()
//
// Parameters:
//
// Remarks:
//
// DirectX notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

bool CAudOutDX::ProcessDXReturn(HRESULT r)
{
  m_err = r;

  switch (r)
  {
  case DS_OK:
    m_err = err_none;
    m_errstr += "None";
    break;
  case DSERR_ALLOCATED:
    m_errstr += "Resource already allocated";
    break;
  case DSERR_INVALIDPARAM:
    m_errstr += "Invalid parameter";
    break;
  case DSERR_ALREADYINITIALIZED: 
    m_errstr += "Object already initialized";
    break;
  case DSERR_BADFORMAT:
    m_errstr += "Specified wave format not supported";
    break;
  case DSERR_BUFFERLOST:
    m_errstr += "Buffer memory lost";
    break;
  case DSERR_CONTROLUNAVAIL:
    m_errstr += "Buffer control (volume, pan, etc) requested not available";
    break;
  case DSERR_GENERIC:
    m_errstr += "Undetermined error inside DirectSound subsystem";
    break;
  case DSERR_INVALIDCALL:
    m_errstr += "DS Function not valid for current state of object"; 
    break;
  case DSERR_NOAGGREGATION: 
    m_errstr += "Object does not support aggregation.";
    break;
  case DSERR_NODRIVER:
    m_errstr += "No sound driver is available for use.";
    break;
  case DSERR_NOINTERFACE:
    m_errstr += "Requested COM interface is not available.";
    break;
  case DSERR_OTHERAPPHASPRIO:
    m_errstr += "Another application has a higher priority level";
    break;
  case DSERR_OUTOFMEMORY: 
    m_errstr += "Out of memory";
    break;
  case DSERR_PRIOLEVELNEEDED:
    m_errstr += "Caller doesn't have priority level required"; 
    break;
  case DSERR_UNINITIALIZED:  
    m_errstr += "Uninitialised";
    break;
  case DSERR_UNSUPPORTED:  
    m_errstr += "Unsupported";
    break;
  default:
    m_errstr += "Unknown";
  }
  return (m_err == err_none);
}

//////////////////////////////////////////////////////////////////////////////
// @Open()
//
// Parameters:
//
// Remarks:
//
// DirectX notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

bool CAudOutDX::Open (short iDevID)
{
  m_err = err_none;

  #ifdef _DEBUG
  m_errstr = "CAudOutDX::Open()";
  #endif

  // incase we haven't been supplied with a window
  // handle...

  if (m_hWnd == NULL)
    m_hWnd = GetDesktopWindow();

  if (CAudOut::Open(iDevID))
  {
    HRESULT  r = DS_OK;

    if (iDevID >= (short) m_dwMaxDS)
    {
      m_err = err_badDevID;
      return false;
    }

    m_dsCaps.dwSize   = sizeof(DSCAPS);
    m_dsbd.dwSize     = sizeof(DSBUFFERDESC);     
    m_dsbd.dwFlags    = DSBCAPS_GLOBALFOCUS         | 
                        DSBCAPS_CTRLDEFAULT         | 
                        DSBCAPS_CTRLPOSITIONNOTIFY  | 
                        DSBCAPS_GETCURRENTPOSITION2; 

    m_dsbd.dwBufferBytes = m_dwBufferSize * m_dwNumBuffers;     
    m_dsbd.dwReserved    = 0; 
    m_dsbd.lpwfxFormat   = &m_wfx; 

    m_dsBCaps.dwSize               = sizeof(DSBCAPS);
    m_dsBCaps.dwFlags              = 0;
    m_dsBCaps.dwBufferBytes        = 0;     
    m_dsBCaps.dwUnlockTransferRate = 0; 
    m_dsBCaps.dwPlayCpuOverhead    = 0; 

    memset(&m_dsbdPrimary, 0, sizeof(DSBUFFERDESC));
    m_dsbdPrimary.dwSize = sizeof(DSBUFFERDESC);
    m_dsbdPrimary.dwFlags = DSBCAPS_PRIMARYBUFFER;

    if ((r = DirectSoundCreate(m_pGUID[iDevID], &m_pDS, NULL)) != DS_OK)
    {
    }
    else if ((r = m_pDS->SetCooperativeLevel (m_hWnd, DSSCL_PRIORITY)) != DS_OK)
    {
    }
    else if ((r = m_pDS->CreateSoundBuffer(&m_dsbdPrimary, &m_pDSBufferPrimary, NULL)) != DS_OK)
    {
    }
    else if ((r = m_pDSBufferPrimary->SetFormat(&m_wfx)) != DS_OK)
    {
    }
    else if (( r = m_pDS->GetCaps(&m_dsCaps)) != DS_OK)
    {
    }
    else if ((r = m_pDS->CreateSoundBuffer(&m_dsbd, &m_pDSBuffer, NULL)) != DS_OK)
    {
    }
    else if ((r = m_pDSBuffer->GetCaps(&m_dsBCaps)) != DS_OK)
    {
    }
    else if ((r = m_pDSBuffer->QueryInterface(IID_IDirectSoundNotify, (void**) &m_pDSNotify)) != DS_OK)
    {
    }
    else
    {
      m_iCurDev = iDevID;
    }
    if (r != DS_OK)
      ProcessDXReturn(r);
  }
  return (m_err == err_none);
} 

//////////////////////////////////////////////////////////////////////////////
// @Close()
//
// Parameters:
//
// Remarks:
//
// DirectX notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

bool CAudOutDX::Close(void)
{
  m_err = err_none;

  #ifdef _DEBUG
  m_errstr = "CAudOutDX::Close() ";
  #endif

  if (m_bActive)
    Stop();

  if (m_pDSNotify)
    m_pDSNotify->Release();
  if (m_pDS)
    m_pDS->Release();

  return true;
}

//////////////////////////////////////////////////////////////////////////////
// @Start()
//
// Parameters:
//
// Remarks:
//
// DirectX notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

// get rid of this global crap!

HANDLE m_dsbe[16]; // 16 = maxbuffers - fix this
//DWORD  p,w;
//long v;
 
bool CAudOutDX::Start(void)
{
  if (!Open (m_iCurDev))
    return false;

  m_err = err_none;

  #ifdef _DEBUG
  m_errstr = "CAudOutDX::Start() ";
  #endif

  if (m_DSPosNotify == NULL)
  {
    m_err = err_badObjectState;
    return false;
  }

  bool    ret = false;
  DWORD   i;
  HRESULT r = DS_OK;
  DWORD   stat;

  for (i = 0; i < m_dwNumBuffers; i++)
  {
    m_dsbe[i]  = CreateEvent(NULL, FALSE, FALSE, NULL);
    m_DSPosNotify[i].dwOffset     = m_dwBufferSize * i;
    m_DSPosNotify[i].hEventNotify = m_dsbe[i];
  }
  if ((r = m_pDSNotify->SetNotificationPositions(m_dwNumBuffers, m_DSPosNotify)) == DS_OK)
  {
    m_bActive    = true;
    m_hAudThread = (HANDLE) _beginthread(AudioThread,0,(void*)this);
    SetThreadPriority(m_hAudThread, m_iAudThreadPriority);
    Sleep(10);
    m_pDSBuffer->SetCurrentPosition(0);
    m_pDSBuffer->GetStatus(&stat);
    if ( ( stat == DSBSTATUS_BUFFERLOST          ) &&
       (( r = m_pDSBuffer->Restore()) != DS_OK )    )
    {
      m_errstr += "Restore() ";
      m_bActive = false;
    }
    else if ((r = m_pDSBuffer->Play(0,0,DSBPLAY_LOOPING)) != DS_OK)
    {
      m_errstr += "Play() ";
      m_bActive = false;
    }
  }
  else
    m_errstr += "SetNotificationPositions() ";

  ret = ProcessDXReturn(r);
 
  return ret;
}

//////////////////////////////////////////////////////////////////////////////
// @ChangeDev()
//
// Parameters:
//
// Remarks:
//
// DirectX notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

bool CAudOutDX::SetCurDev(short iDevID)
{
  m_err = err_none;

  #ifdef _DEBUG
  m_errstr = "CAudOutDX::SetCurDev() ";
  #endif

  if (iDevID < 0 || iDevID >= (short) m_dwNumDev)
    m_err = err_badDevID;
  else if (IsActive())
    m_err = err_notWhileActive;
  else
    m_iCurDev = iDevID;

  return (m_err == err_none);
}

//////////////////////////////////////////////////////////////////////////////
// @DSEnumCallback
//
// Parameters:
//
// Remarks:
//
// DirectX notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

BOOL CALLBACK CAudOutDX::DSEnumCallback (LPGUID lpGuid, LPCSTR lpcstrDescription, LPCSTR lpcstrModule, LPVOID lpContext)
{
  CAudOutDX *pAO = (CAudOutDX*) lpContext;
  if (pAO->m_dwNumDev < pAO->m_dwMaxDS)
  {
    if (lpGuid != NULL)
    {
      pAO->m_pGUID[pAO->m_dwNumDev] = new GUID;
      memcpy(pAO->m_pGUID[pAO->m_dwNumDev], lpGuid, sizeof(GUID));
    }
    else
      pAO->m_pGUID[pAO->m_dwNumDev] = NULL;
    pAO->m_ppchDSDesc[pAO->m_dwNumDev]   = new char[strlen(lpcstrDescription)+1];
    pAO->m_ppchDSModule[pAO->m_dwNumDev] = new char[strlen(lpcstrModule)+1];
    strcpy(pAO->m_ppchDSDesc[pAO->m_dwNumDev],lpcstrDescription);
    strcpy(pAO->m_ppchDSModule[pAO->m_dwNumDev],lpcstrModule);
    pAO->m_dwNumDev++;
    return TRUE;
  }
  else 
    return FALSE;
}

//////////////////////////////////////////////////////////////////////////////
// @GetDSSystemCaps
//
// Parameters:
//
// Remarks:
//
// DirectX notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

bool CAudOutDX::GetDSSystemCaps (void)
{
  m_dwNumDev = 0;
  return DirectSoundEnumerate( DSEnumCallback, this) == DS_OK; 
}

//////////////////////////////////////////////////////////////////////////////
// @AudioThread()
//
// Parameters:
//
// Remarks:
//
// DirectX notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

void CAudOutDX::AudioThread(void* pThis)
{
  CAudOutDX* pAO = (CAudOutDX*) pThis;

  HRESULT r = DS_OK;
  long i;
  float *gen[2];
  DWORD index, lenSam = pAO->m_dwNumSamples;
  DWORD lenByte = pAO->m_dwBufferSize, offset;
  DWORD numBuffs = pAO->m_dwNumBuffers;
  DWORD s;

  DWORD chans = pAO->NumChans();
  DWORD dwI   = pAO->m_dwGenAudioData;

  char  *pvPtr1, *pvPtr2;
  DWORD  dwBytes1, dwBytes2;

  s = numBuffs - 2;

  while (pAO->m_bActive)
  {    
    i = WaitForMultipleObjects (numBuffs, pAO->m_dsbe, FALSE, 10);

    if (i != WAIT_TIMEOUT)
    {
      i -= WAIT_OBJECT_0;

      s++;
      if (s == numBuffs)
        s = 0;

      offset = s * lenByte;
      index  = s * lenSam;
      gen[0] = pAO->m_ppfGenBuffer[0];
      gen[1] = pAO->m_ppfGenBuffer[1];

      memset(gen[0],0,lenByte);
      memset(gen[1],0,lenByte);

      pAO->m_GenAudio(gen, lenSam, chans, dwI);

      r = pAO->m_pDSBuffer->Lock(
                     offset,           // Offset of lock start
                     lenByte,          // Number of bytes to lock
                     (void**)&pvPtr1,  // Address of lock start
                     &dwBytes1,        // Count of bytes locked
                     (void**)&pvPtr2,  // Address of wrap around
                     &dwBytes2,        // Count of wrap around bytes
                     0);               

      if (r == DS_OK)
      {
        pAO->PackOutput(gen,pvPtr1);
      
        r = IDirectSoundBuffer_Unlock(pAO->m_pDSBuffer, 
            pvPtr1, dwBytes1, pvPtr2, dwBytes2);
      }
      if (r != DS_OK)
      {
        pAO->m_bActive = false;
        pAO->ProcessDXReturn(r);
        ASSERT(false);
      }
    }
  } 
  // Clean up after the thread

  for (s=0; s<numBuffs; s++)
    CloseHandle(pAO->m_dsbe[s]);

  pAO->Close();
  pAO->m_hAudThread = NULL;
  _endthread();
}

//////////////////////////////////////////////////////////////////////////////
// @GetDevName
//
// Parameters:
//
// Remarks:
//
// DirectX notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

char* CAudOutDX::GetDevName(DWORD n)
{
  return m_ppchDSDesc[n]; 
}

//////////////////////////////////////////////////////////////////////////////
// @GetDirectSound
//
// Parameters:
//
// Remarks: Returns the DirectSound instance (so DirectMusic can interact with it).
//
// DirectX notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

LPDIRECTSOUND CAudOutDX::GetDirectSound(void)
{
  return m_pDS;
}

//////////////////////////////////////////////////////////////////////////////