#include "MainForm.h"

//#include "ui_mainform.h"
#include "SiUSBLib.h"

MainForm::MainForm(QWidget *parent): QMainWindow(parent),ui(new Ui::MainForm)
{
  ui->setupUi(this);
	InitUSB();
	myUSBdev = new SiUSBDevice(NULL);
	myTLUSB  = new TL_USB(myUSBdev);  // generate USB transfer layer object
	myTLUSB->Open(-1);       // get next available USB device instance
	GPIO1 = new basil_gpio(myTLUSB, 0x1000, 1, true, false);
	UpdateSystem();
}

MainForm::~MainForm(void)
{
  delete ui;
}

void MainForm::UpdateSystem()
{
	std::stringstream ssbuf;
	std::string sbuf;
	void *hUSB = GetUSBDevice(-1);

	if (hUSB != NULL)
	{
		myUSBdev->SetDeviceHandle(hUSB);
		ssbuf << myUSBdev->GetName() << " with ID " << (int)myUSBdev->GetId();
		sbuf = ssbuf.str();
	}
	else
	{
		sbuf = "no board found";
  	myUSBdev->SetDeviceHandle(NULL);
	}
		ui->statusbar->showMessage(sbuf.c_str());
}


void MainForm::onDeviceChange()
{
	if (OnDeviceChange()) // call to SIUSBlib.dll
		UpdateSystem();
}


void MainForm::openFileDialog()
{
	FPGAFileName = QFileDialog::getOpenFileName(this,
		   tr("Select FPGA Configuration File"), "", tr("Bit Files (*.bit)"));

	if (!FPGAFileName.isEmpty())
       ui->fileLineEdit->setText(FPGAFileName);
}

void MainForm::confFPGA()
{
	std::string sb = FPGAFileName.toStdString();
	if (sb != "")
		myUSBdev->DownloadXilinx(sb.c_str());
}

void MainForm::writeClicked()
{
	bool ok;
	GPIO1->Set(ui->writeDataLine->text().toInt(&ok, 16));
}

void MainForm::readClicked()
{
	ui->readDataLine->setText("0x" + QString::number((byte)GPIO1->Get(), 16));  
}

