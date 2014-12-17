//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop
USERES("ReadWaveform.res");
USEFORM("MainReadWaveform.cpp", Form1);
USELIB("..\..\interface\libs\bcsicl32.lib");
USEUNIT("..\..\interface\SILIB_GPIB_Interfaces.cpp");
USEUNIT("Silib_GPIB_TDS.cpp");
USEUNIT("..\Silib_GPIB_Device.cpp");
//---------------------------------------------------------------------------
WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{
  try
  {
     Application->Initialize();
     Application->CreateForm(__classid(TForm1), &Form1);
     Application->Run();
  }
  catch (Exception &exception)
  {
     Application->ShowException(&exception);
  }
  return 0;
}
//---------------------------------------------------------------------------
