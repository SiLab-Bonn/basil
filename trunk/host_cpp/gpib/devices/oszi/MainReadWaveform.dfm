object Form1: TForm1
  Left = 383
  Top = 239
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'TDS Waveform Capture'
  ClientHeight = 606
  ClientWidth = 443
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Icon.Data = {
    0000010002002020100000000000E80200002600000010101000000000002801
    00000E0300002800000020000000400000000100040000000000800200000000
    0000000000000000000000000000000000000000800000800000008080008000
    0000800080008080000080808000C0C0C0000000FF0000FF000000FFFF00FF00
    0000FF00FF00FFFF0000FFFFFF00000000000000000000000000000000000000
    0000000EEE0E0E000000E0EEEEE00000000000E000EE0E000000E0E0000E0000
    000000E0000E0E000000E0E0000E0000000000E00EEE0EEEEE00E0EEEEE00000
    000000E000000E0000E0E0E0000E0888888888E8888E8E8888E8E8E0000E0800
    0008000EEEE00EEEEE00E8EEEEE0080000080000080000080000080000000800
    00080000080000080000080000000800000800000800000800000800000008A0
    000800000800000800000800000008A888888AA88888888888888800000008A0
    00080AAA0800000800000800000008AA00080A0A0800000800000800000008AA
    00080A0AA8000008000008000000080A00080A00AA0000080000A8000000080A
    0008AA000A000008000AA8000000088AA888A8888AA8888888AA880000000800
    A008A00008AA000800A0080000000800A00AA000080A00080AA0080000000800
    AA0AA000080AA0080A000800000008000AAA00000800AA08AA00080000000800
    00AA000008000AAAA00008000000088888888888888888AA8888880000000800
    0008000008000008000008000000080000080000080000080000080000000800
    0008000008000008000008000000080000080000080000080000080000000800
    0008000008000008000008000000088888888888888888888888880000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000280000001000000020000000010004000000
    0000C00000000000000000000000000000000000000000000000000080000080
    00000080800080000000800080008080000080808000C0C0C0000000FF0000FF
    000000FFFF00FF000000FF00FF00FFFF0000FFFFFF0000000000000000000000
    0000000000000888888888888800080000080000080008000008000008000A00
    000A000008000A00000AA000080008A0000A0AA00800088A88A8888A8800080A
    00A8000A08000800AA080000AA0008000A080000080008000008000008000800
    0008000008000888888888888800000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    00000000000000000000000000000000000000000000}
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 8
    Top = 480
    Width = 425
    Height = 81
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 425
    Height = 73
    Caption = 'Init TDS Oscilloscope'
    TabOrder = 1
    object Label1: TLabel
      Left = 40
      Top = 24
      Width = 58
      Height = 13
      Caption = 'Device add.'
    end
    object InitBtn: TButton
      Left = 136
      Top = 20
      Width = 73
      Height = 25
      Caption = 'Init'
      TabOrder = 0
      OnClick = InitBtnClick
    end
    object DevAddEdt: TCSpinEdit
      Left = 48
      Top = 40
      Width = 41
      Height = 22
      TabStop = True
      MaxValue = 32
      MinValue = 1
      ParentColor = False
      TabOrder = 1
      Value = 5
    end
    object DebugOut: TCheckBox
      Left = 136
      Top = 48
      Width = 89
      Height = 17
      Caption = 'debug output'
      TabOrder = 2
    end
    object Button1: TButton
      Left = 312
      Top = 28
      Width = 75
      Height = 25
      Caption = 'Search dev.'
      TabOrder = 3
      OnClick = Button1Click
    end
  end
  object ClrMemoBtn: TButton
    Left = 352
    Top = 568
    Width = 83
    Height = 25
    Caption = 'Clear Memo'
    TabOrder = 2
    OnClick = ClrMemoBtnClick
  end
  object GroupBox3: TGroupBox
    Left = 8
    Top = 400
    Width = 425
    Height = 73
    Caption = 'Save to file...'
    TabOrder = 3
    object Edit1: TEdit
      Left = 16
      Top = 24
      Width = 337
      Height = 21
      TabOrder = 0
      Text = 'default.dat'
    end
    object BrowseFileBtn: TButton
      Left = 360
      Top = 24
      Width = 41
      Height = 25
      Caption = 'Browse'
      TabOrder = 1
      OnClick = BrowseFileBtnClick
    end
    object CheckBox1: TCheckBox
      Left = 16
      Top = 48
      Width = 153
      Height = 17
      Caption = 'auto-increment file name'
      TabOrder = 2
    end
  end
  object PageControl1: TPageControl
    Left = 8
    Top = 88
    Width = 425
    Height = 305
    ActivePage = WfmSheet
    TabOrder = 4
    OnChange = PageControl1Change
    object WfmSheet: TTabSheet
      Caption = 'Waveform'
      object deltaTLbl: TLabel
        Left = 328
        Top = 248
        Width = 28
        Height = 13
        Caption = 't / div'
      end
      object deltaVLbl: TLabel
        Left = 328
        Top = 232
        Width = 32
        Height = 13
        Caption = 'V / div'
      end
      object Chart1: TChart
        Left = 8
        Top = 16
        Width = 313
        Height = 250
        BackWall.Brush.Color = clWhite
        BackWall.Brush.Style = bsClear
        BackWall.Pen.Color = clGray
        Title.Text.Strings = (
          'TChart')
        Title.Visible = False
        BottomAxis.Automatic = False
        BottomAxis.AutomaticMaximum = False
        BottomAxis.AutomaticMinimum = False
        BottomAxis.Axis.Color = clGray
        BottomAxis.Axis.Width = 1
        BottomAxis.AxisValuesFormat = '#e-0'
        BottomAxis.Increment = 1
        BottomAxis.LabelsFont.Charset = DEFAULT_CHARSET
        BottomAxis.LabelsFont.Color = clGray
        BottomAxis.LabelsFont.Height = -11
        BottomAxis.LabelsFont.Name = 'Arial'
        BottomAxis.LabelsFont.Style = []
        BottomAxis.MinorGrid.Color = clGray
        Frame.Color = clGray
        LeftAxis.Automatic = False
        LeftAxis.AutomaticMaximum = False
        LeftAxis.AutomaticMinimum = False
        LeftAxis.Axis.Color = clGray
        LeftAxis.Axis.Width = 1
        LeftAxis.AxisValuesFormat = '#,#e-0'
        LeftAxis.LabelsFont.Charset = DEFAULT_CHARSET
        LeftAxis.LabelsFont.Color = clGray
        LeftAxis.LabelsFont.Height = -11
        LeftAxis.LabelsFont.Name = 'Arial'
        LeftAxis.LabelsFont.Style = []
        LeftAxis.MinorGrid.Color = clGray
        Legend.Visible = False
        RightAxis.Axis.Color = clGray
        RightAxis.MinorGrid.Color = clGray
        TopAxis.Axis.Color = clGray
        TopAxis.MinorGrid.Color = clGray
        View3D = False
        View3DWalls = False
        Color = clBlack
        TabOrder = 0
        object Series1: TLineSeries
          Marks.ArrowLength = 8
          Marks.Visible = False
          SeriesColor = clRed
          Pointer.InflateMargins = True
          Pointer.Style = psRectangle
          Pointer.Visible = False
          XValues.DateTime = False
          XValues.Name = 'X'
          XValues.Multiplier = 1
          XValues.Order = loAscending
          YValues.DateTime = False
          YValues.Name = 'Y'
          YValues.Multiplier = 1
          YValues.Order = loNone
        end
      end
      object SaveCurrentBtn: TButton
        Left = 328
        Top = 168
        Width = 81
        Height = 25
        Caption = 'Save Wafeform'
        TabOrder = 1
        OnClick = SaveCurrentBtnClick
      end
      object SaveBx: TCheckBox
        Left = 328
        Top = 144
        Width = 81
        Height = 17
        Caption = 'and save...'
        TabOrder = 2
      end
      object GetWfmBtn: TButton
        Left = 328
        Top = 112
        Width = 81
        Height = 25
        Caption = 'Get Waveform'
        TabOrder = 3
        OnClick = GetWfmBtnClick
      end
      object RadioGroup1: TRadioGroup
        Left = 328
        Top = 16
        Width = 81
        Height = 89
        Caption = 'Cannel '
        TabOrder = 4
      end
      object Ch1CB: TRadioButton
        Left = 344
        Top = 32
        Width = 50
        Height = 17
        Caption = 'Ch1'
        Checked = True
        TabOrder = 5
        TabStop = True
        OnClick = Ch1CBClick
      end
      object Ch2CB: TRadioButton
        Left = 344
        Top = 48
        Width = 50
        Height = 17
        Caption = 'Ch2'
        TabOrder = 6
        OnClick = Ch2CBClick
      end
      object Ch3CB: TRadioButton
        Left = 344
        Top = 64
        Width = 50
        Height = 17
        Caption = 'Ch3'
        TabOrder = 7
        OnClick = Ch3CBClick
      end
      object Ch4CB: TRadioButton
        Left = 344
        Top = 80
        Width = 50
        Height = 17
        Caption = 'Ch4'
        TabOrder = 8
        OnClick = Ch4CBClick
      end
    end
    object HdCpSheet: TTabSheet
      Caption = 'Hardcopy'
      ImageIndex = 1
      object Image1: TImage
        Left = 8
        Top = 8
        Width = 297
        Height = 249
        Stretch = True
      end
      object HardcopyBtn: TButton
        Left = 320
        Top = 184
        Width = 89
        Height = 25
        Caption = 'Hardcopy'
        TabOrder = 0
        OnClick = HardcopyBtnClick
      end
      object RadioGroup2: TRadioGroup
        Left = 320
        Top = 16
        Width = 89
        Height = 153
        Caption = 'Format'
        TabOrder = 1
        OnClick = PageControl1Change
      end
      object EPSm: TRadioButton
        Left = 328
        Top = 32
        Width = 73
        Height = 17
        Caption = 'EPS mono'
        Checked = True
        TabOrder = 2
        TabStop = True
        OnClick = EPSmClick
      end
      object EPSc: TRadioButton
        Left = 328
        Top = 56
        Width = 73
        Height = 17
        Caption = 'EPS color'
        TabOrder = 3
        OnClick = EPScClick
      end
      object BMP: TRadioButton
        Left = 328
        Top = 80
        Width = 73
        Height = 17
        Caption = 'BMP'
        TabOrder = 4
        OnClick = BMPClick
      end
      object TIFF: TRadioButton
        Left = 328
        Top = 104
        Width = 73
        Height = 17
        Caption = 'TIFF'
        TabOrder = 5
        OnClick = TIFFClick
      end
      object SelLocal: TRadioButton
        Left = 328
        Top = 128
        Width = 73
        Height = 17
        Caption = 'Sel. local'
        TabOrder = 6
        OnClick = SelLocalClick
      end
    end
  end
  object SaveDialog1: TSaveDialog
    Options = [ofOverwritePrompt, ofHideReadOnly, ofShareAware, ofEnableSizing]
    Left = 312
    Top = 568
  end
end
