//---------------------------------------------------------------------------

#include <vcl.h>
#include <stdio.h>
#pragma hdrstop

#include "MainReadWaveform.h"
#include "SILIB_GPIB_Interfaces.h"
#include "Silib_GPIB_TDS.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "CSPIN"
#pragma resource "*.dfm"



#define TDS_GPIB_ADD 5

TGPIB_TDS *Osz;
TGPIB_Interface_USB *GPIB_If;


TForm1 *Form1;
//---------------------------------------------------------------------------
__fastcall TForm1::TForm1(TComponent* Owner)
  : TForm(Owner)
{
  GPIB_If = new TGPIB_Interface_USB(Memo1->Lines);

  // set defaults
  selCh = 1;
  HardcopyFormat = "EPSMono";

  SaveDialog1->DefaultExt = "dat";
  SaveDialog1->Filter = "ASCII data file (*.dat) |*.dat";

  Chart1->Series[0]->Clear();
  for (int i = 0; i < MAX_WFM_POINTS; i++)
    Chart1->Series[0]->AddY(0 ,"", clAqua);

  GPIB_If->SearchDevices(Memo1->Lines);
}
//---------------------------------------------------------------------------

__fastcall TForm1::~TForm1()
{
  if (GPIB_If != NULL)
    delete GPIB_If;
  if (Osz != NULL)
    delete Osz;
}


void __fastcall TForm1::InitBtnClick(TObject *Sender)
{
  int devadd;

  if (Osz != NULL)
    delete Osz;

  if (DebugOut->Checked)
    GPIB_If->SendDebugTo(Memo1->Lines);
  else
    GPIB_If->SendDebugTo(NULL);


  devadd = DevAddEdt->Value;
  Osz    = new TGPIB_TDS(GPIB_If, devadd);
  if (!Osz->isOk)
  {
    delete Osz;
    Osz = NULL;
  }
  else
    Memo1->Lines->Add("Device at ADD " + std::string(devadd) + " found");
}
//---------------------------------------------------------------------------

void __fastcall TForm1::ClrMemoBtnClick(TObject *Sender)
{
  Memo1->Clear();
}
//---------------------------------------------------------------------------

void __fastcall TForm1::GetWfmBtnClick(TObject *Sender)
{
  if (Osz != NULL)
  {
    // read waveform data
    Osz->GetWaveform(selCh);
    // scale chart
    Chart1->LeftAxis->Minimum = -32767.0 * Osz->yScale;
    Chart1->LeftAxis->Maximum =  32767.0 * Osz->yScale;
    Chart1->LeftAxis->Increment = Osz->yScale*65537.0/10.2432; // y-scale factor * ADC_resolution / number of (effektive) y-divisions
    Chart1->BottomAxis->Minimum = 0;
    Chart1->BottomAxis->Maximum = (Osz->nPoints-1) * Osz->xScale;
    Chart1->BottomAxis->Increment = Osz->xScale*Osz->nPoints/10.0; // x-xcale factor * number of samples / number of x-divisions
    deltaVLbl->Caption = FormatFloat("###e+0", Chart1->LeftAxis->Increment) + " V / div";
    deltaTLbl->Caption = FormatFloat("##e+0", Chart1->BottomAxis->Increment) + " s / div";
    //plot data

    for (int i = 0; i < Osz->nPoints; i++)
    {
      Chart1->Series[0]->XValue[i] = (i * Osz->xScale);
      Chart1->Series[0]->YValue[i] = (Osz->wfmData[i]);
    }
    Chart1->Repaint();

    if (SaveBx->Checked)
      SaveWfmDataToFile(Edit1->Text);

  }
}

void __fastcall TForm1::SaveWfmDataToFile(std::string FileName)
{
  FILE *outfile;

  if((outfile = fopen(FileName.c_str(), "w+")) == NULL)
  {
    ShowMessage("Could not open " + FileName + " !");
    return;
  }

  for (int i = 0; i < Osz->nPoints; i++)
    fprintf(outfile, "%e \t %e \n", Chart1->Series[0]->XValue[i], Chart1->Series[0]->YValue[i]);

  fclose(outfile);
}

//---------------------------------------------------------------------------

void __fastcall TForm1::BrowseFileBtnClick(TObject *Sender)
{
  SaveDialog1->FileName = Edit1->Text;
  if(SaveDialog1->Execute())
    Edit1->Text = SaveDialog1->FileName;
}
//---------------------------------------------------------------------------


void __fastcall TForm1::SaveCurrentBtnClick(TObject *Sender)
{
  SaveWfmDataToFile(Edit1->Text);
}
//---------------------------------------------------------------------------

void __fastcall TForm1::HardcopyBtnClick(TObject *Sender)
{
  if (Osz != NULL)
  {
    Osz->HardCopy(Edit1->Text, HardcopyFormat);

    if (HardcopyFormat == "BMP")
     Image1->Picture->LoadFromFile(Edit1->Text);
  }
}
//---------------------------------------------------------------------------

void __fastcall TForm1::Ch1CBClick(TObject *Sender)
{
  selCh = 1;
}
//---------------------------------------------------------------------------

void __fastcall TForm1::Ch2CBClick(TObject *Sender)
{
  selCh = 2;
}
//---------------------------------------------------------------------------

void __fastcall TForm1::Ch3CBClick(TObject *Sender)
{
  selCh = 3;
}
//---------------------------------------------------------------------------

void __fastcall TForm1::Ch4CBClick(TObject *Sender)
{
  selCh = 4;
}
//---------------------------------------------------------------------------

void __fastcall TForm1::EPSmClick(TObject *Sender)
{
  HardcopyFormat = "EPSMono";
  UpdateFileName();
}
//---------------------------------------------------------------------------

void __fastcall TForm1::EPScClick(TObject *Sender)
{
  HardcopyFormat = "EPSColor";
  UpdateFileName();
}
//---------------------------------------------------------------------------

void __fastcall TForm1::BMPClick(TObject *Sender)
{
  HardcopyFormat = "BMP";
  UpdateFileName();
}
//---------------------------------------------------------------------------

void __fastcall TForm1::TIFFClick(TObject *Sender)
{
  HardcopyFormat = "TIFF";
  UpdateFileName();
}
//---------------------------------------------------------------------------
void __fastcall TForm1::SelLocalClick(TObject *Sender)
{
  HardcopyFormat = "LOCAL";
//  UpdateFileName();
}
//---------------------------------------------------------------------------

void __fastcall TForm1::UpdateFileName()
{
  std::string TmpFileName = Edit1->Text;

  if(TmpFileName.Pos(".") == 0)
    TmpFileName = TmpFileName + ".";

  if(PageControl1->ActivePage == HdCpSheet)
  {
    if (HardcopyFormat == "BMP")
    {
      Edit1->Text = TmpFileName.SubString(1, TmpFileName.LastDelimiter(".")) + "bmp";
      SaveDialog1->DefaultExt = "bmp";
      SaveDialog1->Filter = "Bitmap (*.bmp) |*.bmp";
    }
    else
    if (HardcopyFormat == "TIFF")
    {
      Edit1->Text = TmpFileName.SubString(1, TmpFileName.LastDelimiter(".")) + "tif";
      SaveDialog1->DefaultExt = "tif";
      SaveDialog1->Filter = "Tagged image format (*.tif) |*.tif";
    }

    else
    {
      Edit1->Text = TmpFileName.SubString(1, TmpFileName.LastDelimiter(".")) + "eps";
      SaveDialog1->DefaultExt = "eps";
      SaveDialog1->Filter = "Encapsulated postscript (*.eps) |*.eps";
    }
  }
  else
  if(PageControl1->ActivePage == WfmSheet)
  {
    Edit1->Text = TmpFileName.SubString(1, TmpFileName.LastDelimiter(".")) + "dat";
    SaveDialog1->DefaultExt = "dat";
    SaveDialog1->Filter = "ASCII data file (*.dat) |*.dat";
  }


}
//---------------------------------------------------------------------------
void __fastcall TForm1::PageControl1Change(TObject *Sender)
{
  UpdateFileName();
}
//---------------------------------------------------------------------------

void __fastcall TForm1::Button1Click(TObject *Sender)
{
  GPIB_If->SearchDevices(Memo1->Lines);
}
//---------------------------------------------------------------------------


