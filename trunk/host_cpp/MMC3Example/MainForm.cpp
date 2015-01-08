#include "MainForm.h"

//#include "ui_mainform.h"
#include "SiUSBLib.h"

MainForm::MainForm(QWidget *parent): QMainWindow(parent),ui(new Ui::MainForm)
{
	ui->setupUi(this);
	connect(ui->checkBoxEnA, SIGNAL(clicked(bool)), this, SLOT(enablePWRA(bool)));
	connect(ui->checkBoxEnB, SIGNAL(clicked(bool)), this, SLOT(enablePWRB(bool)));
	connect(ui->checkBoxEnC, SIGNAL(clicked(bool)), this, SLOT(enablePWRC(bool)));
	connect(ui->checkBoxEnD, SIGNAL(clicked(bool)), this, SLOT(enablePWRD(bool)));
	connect(ui->measureBtn, SIGNAL(clicked()), this, SLOT(UpdateMeasurements()));

	InitUSB();
	myUSBdev = new SiUSBDevice(NULL);
	myTLUSB  = new TL_USB(myUSBdev);  // generate USB transfer layer object
	myTLUSB->Open(-1);       // get next available USB device instance
	myMMC3   = new HL_MMC3(*myTLUSB);
	GPIO1    = new basil_gpio(myMMC3, "GPIO_LED", 0x1000, 1, true, false);
	UpdateSystem();
	ui->addLine->setText(GPIO1->GetName());
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

void MainForm::enablePWRA(bool isEnabled)
{
	myMMC3->PWR[0]->Switch(isEnabled);
}

void MainForm::enablePWRB(bool isEnabled)
{
	myMMC3->PWR[1]->Switch(isEnabled);
}

void MainForm::enablePWRC(bool isEnabled)
{
	myMMC3->PWR[2]->Switch(isEnabled);
}

void MainForm::enablePWRD(bool isEnabled)
{
	myMMC3->PWR[3]->Switch(isEnabled);
}

void MainForm::UpdateMeasurements()
{
	myMMC3->PWR[0]->UpdateMeasurements();
	myMMC3->PWR[1]->UpdateMeasurements();
	myMMC3->PWR[2]->UpdateMeasurements();
	myMMC3->PWR[3]->UpdateMeasurements();

	ui->lcdNumberAV->display(myMMC3->PWR[0]->GetVoltage());
	ui->lcdNumberBV->display(myMMC3->PWR[1]->GetVoltage());
	ui->lcdNumberCV->display(myMMC3->PWR[2]->GetVoltage());
	ui->lcdNumberDV->display(myMMC3->PWR[3]->GetVoltage());

	ui->lcdNumberAC->display(myMMC3->PWR[0]->GetCurrent());
	ui->lcdNumberBC->display(myMMC3->PWR[1]->GetCurrent());
	ui->lcdNumberCC->display(myMMC3->PWR[2]->GetCurrent());
	ui->lcdNumberDC->display(myMMC3->PWR[3]->GetCurrent());
}
