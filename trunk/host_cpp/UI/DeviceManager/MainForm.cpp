#ifdef WIN32
  #include <qt_windows.h>
  #pragma warning(disable: 4100)
#endif

#include "MainForm.h"

MainForm::MainForm(QWidget *parent, Qt::WindowFlags flags): QMainWindow(parent, flags),ui(new Ui::MainForm)
{
	ui->setupUi(this);
	silab_usb_ico = new QIcon(":/icons/resources/usb.ico");
	QStringList header;
	header << "Id" << "Name" << "Class" << "FW";
	ui->devListTree->setHeaderItem(new QTreeWidgetItem((QTreeWidget *)0, header));
  ui->devListTree->setColumnCount(4);
	ui->devListTree->setColumnWidth(0,60);
	ui->devListTree->setColumnWidth(1,120);
	ui->devListTree->setColumnWidth(2,50);
	ui->devListTree->setColumnWidth(3,50);
	ui->devListTree->setIconSize(QSize(16, 16));
	ui->devListTree->show();
	
	curve1 = new QwtPlotCurve("write");
	curve2 = new QwtPlotCurve("read");
	curve1->attach(ui->benchPlot);
	curve2->attach(ui->benchPlot);
	curve1->setPen(QPen(Qt::blue));
	curve2->setPen(QPen(Qt::green));

	//ui->benchPlot->setAxisScale(QwtPlot::xBottom, 0, 64, 8);
	//ui->benchPlot->setAxisScale(QwtPlot::yLeft, 0, 30, 0);
	ui->benchPlot->setAxisScale(QwtPlot::xBottom, 0, 4000, 0);
	ui->benchPlot->setAxisScale(QwtPlot::yLeft, 0, 300, 0);
	ui->benchPlot->setAxisTitle(QwtPlot::xBottom, QwtText("block size [kbyte]"));
  ui->benchPlot->setAxisTitle(QwtPlot::yLeft,  QwtText("transfer rate [Mbyte/sec]"));
	ui->benchPlot->insertLegend(new QwtLegend(), QwtPlot::RightLegend);

	createActions();

	InitUSB();
	myUSBdev = new SiUSBDevice(NULL);
	UpdateDevList();
	SetCurrentUSBDevice(-1);
  ui->actionExpertMode->setChecked(true);  // test only
	expertModeChanged();
	ui->flashProgressBar->hide();
}

MainForm::~MainForm()
{
	delete curve1;
  delete curve2;
  delete ui;
}

void MainForm::createActions()
{
		showAboutAct = new QAction(tr("&About..."), this);
    connect(ui->actionShowAbout, SIGNAL(triggered()), this, SLOT(showAbout()));

		expertModeAct = new QAction(tr("&Expert mode"), this);
    connect(ui->actionExpertMode, SIGNAL(triggered()), this, SLOT(expertModeChanged()));

		refreshListAct = new QAction(tr("&Refresh list"), this);
    connect(ui->actionRefreshList, SIGNAL(triggered()), this, SLOT(refreshListClicked()));
}

void MainForm::showAbout()
{
	//myAboutForm->show();
	QMessageBox ad;
	ad.setWindowTitle("USB Device Manager");

	ad.setText( "This is the SILAB USB device manager GUI\n"
		"For updates an more information see:\n"
    "http://icwiki.physik.uni-bonn.de/twiki/bin/view/Systems/SILABUSBSoftware");
    
 ad.setInformativeText("Hans Krueger (krueger@physik.uni-bonn.de)");
 ad.setStandardButtons(QMessageBox::Ok);
 ad.setIconPixmap(QPixmap(":/icons/resources/silab_usb.ico"));
 ad.exec();
 ad.close();
}

void MainForm::refreshListClicked()
{
  UpdateDevList();
}

void MainForm::expertModeChanged()
{
	int indx;
	if (ui->actionExpertMode->isChecked())
	{
		ui->firmwareTab->setEnabled(true);
		ui->fpgaTab->setEnabled(true);
		if ((indx = ui->modeComboBox->findText("EEPROM", Qt::MatchFixedString) ) != -1)
 	    ui->modeComboBox->removeItem(indx);  
		ui->modeComboBox->addItem("EEPROM");
	}
	else
	{
		ui->firmwareTab->setEnabled(false);
		ui->fpgaTab->setEnabled(false);
		ui->modeComboBox->removeItem(ui->modeComboBox->findText("EEPROM", Qt::MatchFixedString));
	}
}



void MainForm::SetCurrentUSBDevice(int id)
{
	std::stringstream ssbuf;
	std::string sbuf;
	void *hUSB = GetUSBDevice(id);

	if (hUSB != NULL)
	{
		myUSBdev->SetDeviceHandle(hUSB);
		ssbuf << "Current device: " << myUSBdev->GetName() << " with ID " << (int)myUSBdev->GetId();
		statusBar()->showMessage(ssbuf.str().c_str());
	  ui->infoWindow->setText(QString(myUSBdev->GetEndpointInfo()));
		ui->classLineEdit->setText(QString::number(myUSBdev->GetClass()));
		ui->IdLineEdit->setText(QString::number(myUSBdev->GetId()));
		ui->nameLineEdit->setText(QString(myUSBdev->GetName()));
	}
	else
	{
		myUSBdev->SetDeviceHandle(NULL);
		statusBar()->showMessage("No USB device found or selected.");
		ui->infoWindow->setText("");
	}
}


void MainForm::onDeviceChange()
{
	if (OnDeviceChange()) // call to USBBoardLib.dll
	{
		UpdateDevList();
		SetCurrentUSBDevice(-1);
	}

}

void MainForm::openFPGADialog()
{

// static version -> native OS dialog
  QString fileName = QFileDialog::getOpenFileName(this,
     tr("Select FPGA configuration file"), ".", tr("BIT Files (*.bit)"));
  ui->fpgaFileLineEdit->setText(fileName);
}

void MainForm::openControllerDialog()
{
// static version -> native OS dialog
  QString fileName = QFileDialog::getOpenFileName(this,
     tr("Select USB controller firmware"), ".", tr("BIX Files (*.bix)"));
  ui->controllerFileLineEdit->setText(fileName);
} 

void MainForm::openEEPROMDialog()
{

// static version -> native OS dialog
  QString fileName = QFileDialog::getOpenFileName(this,
     tr("Select USB controller firmware"), ".", tr("HEX Files (*.hex)"));
  ui->eepromFileLineEdit->setText(fileName);
}

void MainForm::loadFPGA()
{
	if (!ui->fpgaFileLineEdit->text().isEmpty())
		myUSBdev->DownloadXilinx(ui->fpgaFileLineEdit->text().toLatin1());
}

void MainForm::loadController()
{
	if (!ui->controllerFileLineEdit->text().isEmpty())
  {
		myUSBdev->LoadFirmwareFromFile(ui->controllerFileLineEdit->text().toLatin1());
	}
}

void MainForm::doflashEEPROM()
{
	if (!ui->eepromFileLineEdit->text().isEmpty())
		myUSBdev->LoadHexFileToEeprom(ui->eepromFileLineEdit->text().toLatin1());
}


unsigned long MainForm::MyThreadFunc(void* ptr)
{
	MainForm *hdl = (MainForm *)ptr;
	hdl->doflashEEPROM();
  return 1;
}

void MainForm::flashEEPROM()
{
	if (!ui->eepromFileLineEdit->text().isEmpty())
	{
		unsigned long tId;
		ui->flashProgressBar->show();
#ifdef WIN32
		HANDLE tFlash = CreateThread(0, 0, (LPTHREAD_START_ROUTINE) MyThreadFunc, this, 0, &tId); 
		while(WaitForSingleObject(tFlash, 0))
#endif
    	 QCoreApplication::processEvents();
		ui->flashProgressBar->hide();
	}
}


void MainForm::updateDeviceId()
{
	myUSBdev->WriteIDToEEPROM(ui->IdLineEdit->text().toInt());
	myUSBdev->WriteNameToEEPROM(ui->nameLineEdit->text().toLatin1());
	myUSBdev->WriteDeviceClassToEEPROM(ui->classLineEdit->text().toInt());

	UpdateDevList();
}


void MainForm::listItemClicked(QTreeWidgetItem *currentItem, int column)
{
	SetCurrentUSBDevice(devListItems[ui->devListTree->indexOfTopLevelItem(currentItem)]->text(0).toInt());
}

void MainForm::UpdateDevList()
{
 // int numDev = GetNumberOfUSBBoards();
	QStringList devInfoString;
	std::string devId, devName, devClass, devFirmware;
	std::stringstream tmp;
	QTreeWidgetItem *tmpItem;
	SiUSBDevice tmpDev(NULL);

	devListItems.clear();
	ui->devListTree->clear();

	for (int i = 0; i < GetMaxNumberOfUSBBoards(); i++)
	{
		if (GetUSBDeviceIndexed(i) != NULL)
		{
			tmpDev.SetDeviceHandle(GetUSBDeviceIndexed(i));
			devInfoString.clear();
			tmpDev.GetUserInformation();
			devInfoString << QString::number((int)tmpDev.GetId()) << QString(tmpDev.GetName()) << QString::number(tmpDev.GetClass()) << QString::number(tmpDev.GetFWVersion());
			tmpItem = new QTreeWidgetItem(ui->devListTree, devInfoString);
			tmpItem->setIcon(0, *silab_usb_ico);
			devListItems.append(tmpItem);
  	}
	}
  ui->devListTree->insertTopLevelItems(0, devListItems);
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
		if (ui->hexCheckBox->isChecked())
			ins >> std::hex >> sBuffer[i] ;
		else
			ins >>  sBuffer[i] ;
		buffer[i] = (unsigned char)(0xff & sBuffer[i]);
		count ++;
	}

	ui->sizeLine->setText(QString::number(count));

	/*  debug
	for (int i = 0; i < count; i++)
	{
  	outs << (int)buffer[i] << " ";
	}
	readDataLine->setText(QString(outs.str().c_str()));  
  */

	if (ui->modeComboBox->currentText() == QString("External"))
		myUSBdev->WriteExternal(ui->addLine->text().toInt(), buffer, count);
	else
	if (ui->modeComboBox->currentText() == QString("FPGA"))
		myUSBdev->WriteXilinx(ui->addLine->text().toInt(), buffer, count);
	else
	if (ui->modeComboBox->currentText() == QString("Command"))
		myUSBdev->WriteCommand(buffer, count);
	else
	if (ui->modeComboBox->currentText() == QString("I2C"))
		myUSBdev->WriteI2C(ui->addLine->text().toInt(), buffer, count);
	else
	if (ui->modeComboBox->currentText() == QString("EEPROM"))
		myUSBdev->WriteEEPROM(ui->addLine->text().toInt(), buffer, count);
	else
	if (ui->modeComboBox->currentText() == QString("SPI"))
		myUSBdev->WriteSPI(ui->addLine->text().toInt(), buffer, count);
	else
	if (ui->modeComboBox->currentText() == QString("UART"))
		myUSBdev->WriteSerial(buffer, count);
	else
	if (ui->modeComboBox->currentText() == QString("Controller"))
		myUSBdev->Write8051(ui->addLine->text().toInt(), buffer, count);
	else
	if (ui->modeComboBox->currentText() == QString("Register"))
		myUSBdev->WriteRegister(&buffer[0]);
	else
	if (ui->modeComboBox->currentText() == QString("Block"))
		myUSBdev->WriteBlock(ui->addLine->text().toLongLong(), buffer, count);
}

void MainForm::readClicked()
{
  unsigned char buffer[16];
	std::stringstream outs;
	int count = std::min(16, ui->sizeLine->text().toInt());

	if (ui->modeComboBox->currentText() == QString("External"))
		myUSBdev->ReadExternal(ui->addLine->text().toInt(), buffer, count);
	else
	if (ui->modeComboBox->currentText() == QString("FPGA"))
		myUSBdev->ReadXilinx(ui->addLine->text().toInt(), buffer, count);
	else
	if (ui->modeComboBox->currentText() == QString("I2C"))
		myUSBdev->ReadI2C(ui->addLine->text().toInt(), buffer, count);
	else
	if (ui->modeComboBox->currentText() == QString("EEPROM"))
		myUSBdev->ReadEEPROM(ui->addLine->text().toInt(), buffer, count);
	else
	if (ui->modeComboBox->currentText() == QString("SPI"))
		myUSBdev->ReadSPI(ui->addLine->text().toInt(), buffer, count);
	else
	if (ui->modeComboBox->currentText() == QString("UART"))
		myUSBdev->ReadSerial(buffer, count);
	else
	if (ui->modeComboBox->currentText() == QString("Controller"))
		myUSBdev->Read8051(ui->addLine->text().toInt(), buffer, count);
	else
	if (ui->modeComboBox->currentText() == QString("Register"))
		myUSBdev->ReadRegister(buffer);
	else
	if (ui->modeComboBox->currentText() == QString("Block"))
		myUSBdev->ReadBlock(ui->addLine->text().toLongLong(), buffer, count);

	for (int i = 0; i < count; i++)
	{
		if (ui->hexCheckBox->isChecked())
			outs << std::hex << (int)buffer[i] << " ";
		else
  	  outs << (int)buffer[i] << " ";
	}

	ui->readDataLine->setText(QString(outs.str().c_str()));  

}

void MainForm::runBenchmark()
{
	long long addr = 0x10000; // Address offset = 0 and it's a memory access
	QTime myTimer;
	//int chunkSize = 4*0x10000; // 4*64*1k // 8*1k // was 4k // was 256
	//int bufferSize = 0x3E8000; // 4M // 4*64k // was 2M // was 13568 // was 12288
	//int chunkSize = 0x1000; // 4k
	//int bufferSize = 0x10000; // 64k
	int chunkSize = 0x400; // 1k
	int bufferSize = (7*0x2000); // 8k
	int numBlocks = bufferSize/chunkSize;
	int blockSize;
	int cycles = 0;
	unsigned char *buffer = new unsigned char[bufferSize];
  double *x  = new double[numBlocks];
  double *yw = new double[numBlocks];
  double *yr = new double[numBlocks];
	int ptr = 0;
	int stopTime;
	//long t1;
	//long t2;

	myTimer.start();


	for (int i=1; i <= /*1*/numBlocks; i++)
	{ 
		//blockSize = 12*1024.0;
		blockSize = i * chunkSize;
		x[ptr] = (double) blockSize / 1024.0; // block size in kbytes
		cycles = (numBlocks + 2 - i) * 4;
    
		// write loop
	  myTimer.restart();
		for(int j=0; j < /*1*/cycles; j++)
			//myUSBdev->WriteBlock(buffer, 1*1024.0);
			myUSBdev->WriteBlock(addr, buffer, blockSize);
		stopTime = myTimer.elapsed();
		yw[ptr] = x[ptr] / ((double) stopTime / cycles); // kbyte / ms
#if QWT_VERSION < 0x060000
	  curve1->setData(x, yw, i);     
#else
    curve1->setSamples(x, yw, i);
#endif


	  /*for (t1=0; t1 < 10000; t1++)
		for (t2=0; t2 < 10000; t2++); // delay between writing and reading

	  t1 = 0;
	  t2 = 0;*/

		// read loop
	  myTimer.restart();
		for(int j=0; j < /*1*/cycles; j++)
			//myUSBdev->ReadBlock(buffer, 1024.0);
			myUSBdev->ReadBlock(addr, buffer, blockSize);
		stopTime = myTimer.elapsed();
		yr[ptr] = x[ptr] / ((double) stopTime / cycles); // kbyte / ms
#if QWT_VERSION < 0x060000
		curve2->setData(x, yr, i); 
#else
    curve2->setSamples(x, yr, i);


	/*for (t1=0; t1 < 10000; t1++)
		for (t2=0; t2 < 10000; t2++); // delay between reading and writing

	t1 = 0;
	t2 = 0;*/

#endif
    QCoreApplication::processEvents();
    ui->benchPlot->replot();
		ptr++;
	}

	/*myTimer.restart();
	for (int i = 0; i < 10000; i++)
    myUSBdev->ReadFPGA(0, buffer);
	stopTime = myTimer.elapsed();
	ui->rateLabel->setText(QString("%1 kHz").arg(10000.0/(double)stopTime));*/

	delete[] buffer;
	delete[] x;
	delete[] yw;
	delete[] yr;
}

 void MainForm::selectMode(QString mode)
{
  ;
}

 
void MainForm:: runIntegrityTest()
{
	long long addr = 0x10000; // Address offset = 0 and it's a memory access
	int bufferSize = (1*0x400-32); // 1-32k
	int error = 0;
	unsigned char *write_buffer = new unsigned char[bufferSize];
	unsigned char *read_buffer = new unsigned char[bufferSize];
	int *error_positions = new int[bufferSize];
	

	ui->TransferredBrowser->clear();
	ui->ReceivedBrowser->clear();

	for (int i = 0; i < bufferSize; i++){
		write_buffer[i] = qrand() % 256;
		//write_buffer[i] = i;
		ui->TransferredBrowser->append(QString("%1:    %2").arg(i).arg(write_buffer[i]));
			//setText(QString("%1\n").arg(buffer[i]));
	}

	myUSBdev->WriteBlock(addr, write_buffer, bufferSize);

	//Sleep(50);

	myUSBdev->ReadBlock(addr, read_buffer, bufferSize);
	//myUSBdev->ReadBlock(read_buffer, bufferSize); // without second call read_buffer will keep the data from the previous write_buffer!

	for (int i = 0; i < bufferSize; i++){
		ui->ReceivedBrowser->append(QString("%1:    %2").arg(i).arg(read_buffer[i]));
	}

	for (int i = 0; i < bufferSize; i++){
		if (write_buffer[i] == read_buffer[i]){
		
		}else{
			error_positions[error] = i;
			error++;
		}
	}

	if (error == 0){
		ui->StatusBrowser->setText(QString("Success: no data integrity errors"));
	}else{
		ui->StatusBrowser->setText(QString("Fail: data integrity errors at the following positions:"));
		for (int i = 0; i < error; i++){
			ui->StatusBrowser->append(QString("%1").arg(error_positions[i]));
		}
	}

	delete[] write_buffer;
	delete[] read_buffer;
	delete[] error_positions;
}