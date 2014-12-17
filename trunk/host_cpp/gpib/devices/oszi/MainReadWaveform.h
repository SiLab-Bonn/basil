//---------------------------------------------------------------------------

#ifndef MainReadWaveformH
#define MainReadWaveformH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "CSPIN.h"
#include <Chart.hpp>
#include <ExtCtrls.hpp>
#include <Series.hpp>
#include <TeEngine.hpp>
#include <TeeProcs.hpp>
#include <Dialogs.hpp>
#include <ComCtrls.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// Von der IDE verwaltete Komponenten
  TMemo *Memo1;
  TGroupBox *GroupBox1;
  TButton *InitBtn;
  TLabel *Label1;
  TCSpinEdit *DevAddEdt;
  TButton *ClrMemoBtn;
  TCheckBox *DebugOut;
  TGroupBox *GroupBox3;
  TSaveDialog *SaveDialog1;
  TEdit *Edit1;
  TButton *BrowseFileBtn;
  TCheckBox *CheckBox1;
  TPageControl *PageControl1;
  TTabSheet *WfmSheet;
  TTabSheet *HdCpSheet;
  TChart *Chart1;
  TLineSeries *Series1;
  TLabel *deltaTLbl;
  TLabel *deltaVLbl;
  TButton *SaveCurrentBtn;
  TCheckBox *SaveBx;
  TButton *GetWfmBtn;
  TRadioGroup *RadioGroup1;
  TRadioButton *Ch1CB;
  TRadioButton *Ch2CB;
  TRadioButton *Ch3CB;
  TRadioButton *Ch4CB;
  TButton *HardcopyBtn;
  TRadioGroup *RadioGroup2;
  TRadioButton *EPSm;
  TRadioButton *EPSc;
  TRadioButton *BMP;
  TRadioButton *TIFF;
  TImage *Image1;
  TButton *Button1;
  TRadioButton *SelLocal;
  void __fastcall InitBtnClick(TObject *Sender);
  void __fastcall ClrMemoBtnClick(TObject *Sender);
  void __fastcall GetWfmBtnClick(TObject *Sender);
  void __fastcall BrowseFileBtnClick(TObject *Sender);
  void __fastcall SaveCurrentBtnClick(TObject *Sender);
  void __fastcall HardcopyBtnClick(TObject *Sender);
  void __fastcall Ch1CBClick(TObject *Sender);
  void __fastcall Ch2CBClick(TObject *Sender);
  void __fastcall Ch3CBClick(TObject *Sender);
  void __fastcall Ch4CBClick(TObject *Sender);
  void __fastcall EPSmClick(TObject *Sender);
  void __fastcall EPScClick(TObject *Sender);
  void __fastcall BMPClick(TObject *Sender);
  void __fastcall TIFFClick(TObject *Sender);
  void __fastcall PageControl1Change(TObject *Sender);
  void __fastcall Button1Click(TObject *Sender);
  void __fastcall SelLocalClick(TObject *Sender);
private:	// Anwender-Deklarationen
public:		// Anwender-Deklarationen
  __fastcall TForm1(TComponent* Owner);
  __fastcall ~TForm1();
  void __fastcall SaveWfmDataToFile(std::string FileName);
  void __fastcall UpdateFileName();
  int selCh;
  std::string HardcopyFormat;
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
