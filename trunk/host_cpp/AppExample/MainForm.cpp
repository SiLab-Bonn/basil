#include "MainForm.h"
//#include "ui_mainform.h"
#include "SiUSBLib.h"

MainForm::MainForm(QWidget *parent): QMainWindow(parent),ui(new Ui::MainForm)
{
  ui->setupUi(this);
	InitUSB();
	myUSBdev = new SiUSBDevice(NULL);
	UpdateSystem();

	// setup plot curve
	curve1 = new QwtPlotCurve("data 1");
	curve2 = new QwtPlotCurve("data 2");
	curve1->attach(ui->qwtPlot1);
	curve2->attach(ui->qwtPlot1);
	curve1->setPen(QPen(Qt::blue));
	curve2->setPen(QPen(Qt::green));

//	ui->qwtPlot1->setAxisScale(QwtPlot::xBottom, 0, 64, 8);
//	ui->qwtPlot1->setAxisScale(QwtPlot::yLeft, 0, 30, 0);
	ui->qwtPlot1->setAxisTitle(QwtPlot::xBottom, QwtText("x-data [some unit]"));
  ui->qwtPlot1->setAxisTitle(QwtPlot::yLeft,  QwtText("y-data [a.u.]"));
	ui->qwtPlot1->insertLegend(new QwtLegend(), QwtPlot::RightLegend);

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
	std::stringstream ins;
	std::stringstream outs;
	int sBuffer[16];
	unsigned char buffer[16];
	int count = 0;

	ins << ui->writeDataLine->text().toStdString();

	for (int i = 0; (i < 16) && !ins.eof(); i++)
	{
		ins >> std::hex >> sBuffer[i] ;
		buffer[i] = (unsigned char)(0xff & sBuffer[i]);
		count ++;
	}

	ui->spinBox->setValue(count);

	myUSBdev->WriteExternal(ui->addLine->text().toInt(), buffer, count);
}

void MainForm::readClicked()
{
  unsigned char buffer[16];
	std::stringstream outs;
	int count = std::min(16, ui->spinBox->value());

	myUSBdev->ReadExternal(ui->addLine->text().toInt(), buffer, count);

	for (int i = 0; i < count; i++)
	{
		outs << std::hex << " 0x" << std::setfill('0') << std::setw(2) <<  (int)buffer[i] << " ";
	}
	ui->readDataLine->setText(QString(outs.str().c_str()));  
}

void MainForm::plotData()
{
	double x[100];
  double y[100];

	for (int i = 0; i < 100; i++)
	{  
		x[i] = i;
    y[i] = 50 + 25*sin(1/10.0*x[i] + rand());
	}
#if QWT_VERSION < 0x060000
    curve1->setData(x, y, 100);
#else
    curve1->setSamples(x, y, 100);
#endif
  ui->qwtPlot1->axisAutoScale(QwtPlot::xBottom);
  ui->qwtPlot1->axisAutoScale(QwtPlot::yLeft);
  ui->qwtPlot1->replot();
}
