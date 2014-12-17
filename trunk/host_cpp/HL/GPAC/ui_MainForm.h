/********************************************************************************
** Form generated from reading UI file 'MainForm.ui'
**
** Created by: Qt User Interface Compiler version 5.2.1
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_MAINFORM_H
#define UI_MAINFORM_H

#include <QtCore/QVariant>
#include <QtWidgets/QAction>
#include <QtWidgets/QApplication>
#include <QtWidgets/QButtonGroup>
#include <QtWidgets/QCheckBox>
#include <QtWidgets/QComboBox>
#include <QtWidgets/QDoubleSpinBox>
#include <QtWidgets/QGridLayout>
#include <QtWidgets/QGroupBox>
#include <QtWidgets/QHeaderView>
#include <QtWidgets/QLCDNumber>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QRadioButton>
#include <QtWidgets/QSpacerItem>
#include <QtWidgets/QSpinBox>
#include <QtWidgets/QTabWidget>
#include <QtWidgets/QTextBrowser>
#include <QtWidgets/QToolButton>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_MainForm
{
public:
    QTabWidget *tabWidget;
    QWidget *Seite;
    QTextBrowser *memo1;
    QPushButton *calBtn;
    QComboBox *chSelBox;
    QPushButton *updateEEPROMBtn;
    QPushButton *dumpEEPROMBtn;
    QLabel *label_7;
    QSpinBox *IdNumBox;
    QWidget *Seite_2;
    QPushButton *refreshDCSButton;
    QWidget *layoutWidget_5;
    QGridLayout *gridLayout_13;
    QCheckBox *PWR1CheckBox;
    QLabel *label_67;
    QLabel *label_68;
    QDoubleSpinBox *PWR1spin;
    QLCDNumber *PWR1VLCD;
    QLCDNumber *PWR1CLCD;
    QDoubleSpinBox *PWR0spin;
    QLCDNumber *PWR0VLCD;
    QLCDNumber *PWR0CLCD;
    QCheckBox *PWR2CheckBox;
    QDoubleSpinBox *PWR2spin;
    QLCDNumber *PWR2CLCD;
    QCheckBox *PWR3CheckBox;
    QDoubleSpinBox *PWR3spin;
    QLCDNumber *PWR3VLCD;
    QLCDNumber *PWR3CLCD;
    QSpacerItem *verticalSpacer;
    QLabel *label_26;
    QLabel *label_8;
    QCheckBox *PWR0CheckBox;
    QLabel *label_9;
    QDoubleSpinBox *VSRC0spin;
    QLabel *label_10;
    QDoubleSpinBox *VSRC2spin;
    QLCDNumber *VSRC0VLCD;
    QDoubleSpinBox *ISRC1spin;
    QLabel *label_12;
    QLCDNumber *ISRC0CLCD;
    QLabel *label_24;
    QLCDNumber *VSRC0CLCD;
    QLabel *label_14;
    QLabel *label_16;
    QLCDNumber *ISRC1CLCD;
    QLabel *label_15;
    QLCDNumber *ISRC1VLCD;
    QDoubleSpinBox *VSRC3spin;
    QLCDNumber *VSRC1CLCD;
    QLCDNumber *VSRC3CLCD;
    QLCDNumber *VSRC2VLCD;
    QLabel *label_13;
    QLCDNumber *ISRC0VLCD;
    QDoubleSpinBox *ISRC0spin;
    QLabel *label_11;
    QLCDNumber *VSRC1VLCD;
    QLCDNumber *VSRC2CLCD;
    QLCDNumber *VSRC3VLCD;
    QDoubleSpinBox *VSRC1spin;
    QLCDNumber *PWR2VLCD;
    QLabel *label_23;
    QLCDNumber *ISRC2VLCD;
    QDoubleSpinBox *ISRC3spin;
    QLCDNumber *ISRC2CLCD;
    QLCDNumber *ISRC3VLCD;
    QLabel *label_18;
    QLCDNumber *ISRC3CLCD;
    QLabel *label_17;
    QDoubleSpinBox *ISRC2spin;
    QLabel *PWRname_0;
    QLabel *PWRname_1;
    QLabel *PWRname_2;
    QLabel *PWRname_3;
    QLabel *VSRCname_0;
    QLabel *VSRCname_1;
    QLabel *VSRCname_2;
    QLabel *VSRCname_3;
    QLabel *ISRCname_0;
    QLabel *ISRCname_1;
    QLabel *ISRCname_2;
    QLabel *ISRCname_3;
    QLabel *label_69;
    QLabel *label_70;
    QLabel *label_71;
    QLabel *label_72;
    QLabel *label_25;
    QDoubleSpinBox *CurrLimBox;
    QCheckBox *checkBox;
    QWidget *Keithley24xxTab;
    QPushButton *measBtn;
    QGroupBox *groupBox;
    QRadioButton *currBtn;
    QRadioButton *voltageBtn;
    QGroupBox *groupBox_2;
    QToolButton *onBtn;
    QToolButton *offBtn;
    QPushButton *setBtn;
    QLCDNumber *voltageLCD;
    QLCDNumber *currentLCD;
    QLabel *label_3;
    QLabel *label_4;
    QDoubleSpinBox *voltageVal;
    QDoubleSpinBox *currentVal;
    QLabel *label_5;
    QLabel *label_6;
    QWidget *sysTab;
    QPushButton *confFPGAButton;
    QToolButton *fileDialogButton;
    QLineEdit *fileLineEdit;
    QWidget *GPIBTab;
    QTextBrowser *textBrowser;
    QPushButton *refreshListBtn;
    QPushButton *sendReceiveBtn;
    QLineEdit *deviceIdEdit;
    QLabel *label;
    QLabel *label_2;
    QLineEdit *commandEdit;
    QPushButton *sendBtn;
    QPushButton *clearGPIBBtn;
    QLabel *statusLabel;

    void setupUi(QWidget *MainForm)
    {
        if (MainForm->objectName().isEmpty())
            MainForm->setObjectName(QStringLiteral("MainForm"));
        MainForm->resize(544, 669);
        QSizePolicy sizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
        sizePolicy.setHorizontalStretch(0);
        sizePolicy.setVerticalStretch(0);
        sizePolicy.setHeightForWidth(MainForm->sizePolicy().hasHeightForWidth());
        MainForm->setSizePolicy(sizePolicy);
        QIcon icon;
        icon.addFile(QStringLiteral("../../../../../../Dokumente und Einstellungen/Hans/.designer/res/silab.ico"), QSize(), QIcon::Normal, QIcon::Off);
        MainForm->setWindowIcon(icon);
        MainForm->setStyleSheet(QStringLiteral(""));
        tabWidget = new QTabWidget(MainForm);
        tabWidget->setObjectName(QStringLiteral("tabWidget"));
        tabWidget->setGeometry(QRect(10, 0, 521, 641));
        Seite = new QWidget();
        Seite->setObjectName(QStringLiteral("Seite"));
        memo1 = new QTextBrowser(Seite);
        memo1->setObjectName(QStringLiteral("memo1"));
        memo1->setGeometry(QRect(10, 10, 501, 411));
        QFont font;
        font.setFamily(QStringLiteral("Courier New"));
        font.setPointSize(10);
        memo1->setFont(font);
        calBtn = new QPushButton(Seite);
        calBtn->setObjectName(QStringLiteral("calBtn"));
        calBtn->setGeometry(QRect(10, 430, 75, 23));
        chSelBox = new QComboBox(Seite);
        chSelBox->setObjectName(QStringLiteral("chSelBox"));
        chSelBox->setGeometry(QRect(100, 430, 61, 22));
        updateEEPROMBtn = new QPushButton(Seite);
        updateEEPROMBtn->setObjectName(QStringLiteral("updateEEPROMBtn"));
        updateEEPROMBtn->setGeometry(QRect(300, 430, 101, 23));
        dumpEEPROMBtn = new QPushButton(Seite);
        dumpEEPROMBtn->setObjectName(QStringLiteral("dumpEEPROMBtn"));
        dumpEEPROMBtn->setGeometry(QRect(410, 430, 101, 23));
        label_7 = new QLabel(Seite);
        label_7->setObjectName(QStringLiteral("label_7"));
        label_7->setGeometry(QRect(215, 430, 21, 20));
        IdNumBox = new QSpinBox(Seite);
        IdNumBox->setObjectName(QStringLiteral("IdNumBox"));
        IdNumBox->setGeometry(QRect(240, 430, 42, 22));
        IdNumBox->setLayoutDirection(Qt::LeftToRight);
        IdNumBox->setMaximum(100);
        tabWidget->addTab(Seite, QString());
        Seite_2 = new QWidget();
        Seite_2->setObjectName(QStringLiteral("Seite_2"));
        refreshDCSButton = new QPushButton(Seite_2);
        refreshDCSButton->setObjectName(QStringLiteral("refreshDCSButton"));
        refreshDCSButton->setGeometry(QRect(400, 30, 111, 51));
        layoutWidget_5 = new QWidget(Seite_2);
        layoutWidget_5->setObjectName(QStringLiteral("layoutWidget_5"));
        layoutWidget_5->setGeometry(QRect(20, 10, 368, 541));
        gridLayout_13 = new QGridLayout(layoutWidget_5);
        gridLayout_13->setSpacing(6);
        gridLayout_13->setObjectName(QStringLiteral("gridLayout_13"));
        gridLayout_13->setContentsMargins(0, 0, 0, 0);
        PWR1CheckBox = new QCheckBox(layoutWidget_5);
        PWR1CheckBox->setObjectName(QStringLiteral("PWR1CheckBox"));

        gridLayout_13->addWidget(PWR1CheckBox, 7, 0, 1, 1);

        label_67 = new QLabel(layoutWidget_5);
        label_67->setObjectName(QStringLiteral("label_67"));

        gridLayout_13->addWidget(label_67, 0, 3, 1, 1);

        label_68 = new QLabel(layoutWidget_5);
        label_68->setObjectName(QStringLiteral("label_68"));

        gridLayout_13->addWidget(label_68, 0, 4, 1, 1);

        PWR1spin = new QDoubleSpinBox(layoutWidget_5);
        PWR1spin->setObjectName(QStringLiteral("PWR1spin"));
        PWR1spin->setDecimals(0);
        PWR1spin->setMinimum(800);
        PWR1spin->setMaximum(2800);
        PWR1spin->setSingleStep(10);
        PWR1spin->setValue(1800);

        gridLayout_13->addWidget(PWR1spin, 7, 2, 1, 1);

        PWR1VLCD = new QLCDNumber(layoutWidget_5);
        PWR1VLCD->setObjectName(QStringLiteral("PWR1VLCD"));
        PWR1VLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(PWR1VLCD, 7, 3, 1, 1);

        PWR1CLCD = new QLCDNumber(layoutWidget_5);
        PWR1CLCD->setObjectName(QStringLiteral("PWR1CLCD"));
        PWR1CLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(PWR1CLCD, 7, 4, 1, 1);

        PWR0spin = new QDoubleSpinBox(layoutWidget_5);
        PWR0spin->setObjectName(QStringLiteral("PWR0spin"));
        PWR0spin->setDecimals(0);
        PWR0spin->setMinimum(800);
        PWR0spin->setMaximum(2800);
        PWR0spin->setSingleStep(10);
        PWR0spin->setValue(1800);

        gridLayout_13->addWidget(PWR0spin, 6, 2, 1, 1);

        PWR0VLCD = new QLCDNumber(layoutWidget_5);
        PWR0VLCD->setObjectName(QStringLiteral("PWR0VLCD"));
        PWR0VLCD->setMode(QLCDNumber::Dec);
        PWR0VLCD->setSegmentStyle(QLCDNumber::Flat);
        PWR0VLCD->setProperty("value", QVariant(0));

        gridLayout_13->addWidget(PWR0VLCD, 6, 3, 1, 1);

        PWR0CLCD = new QLCDNumber(layoutWidget_5);
        PWR0CLCD->setObjectName(QStringLiteral("PWR0CLCD"));
        PWR0CLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(PWR0CLCD, 6, 4, 1, 1);

        PWR2CheckBox = new QCheckBox(layoutWidget_5);
        PWR2CheckBox->setObjectName(QStringLiteral("PWR2CheckBox"));

        gridLayout_13->addWidget(PWR2CheckBox, 8, 0, 1, 1);

        PWR2spin = new QDoubleSpinBox(layoutWidget_5);
        PWR2spin->setObjectName(QStringLiteral("PWR2spin"));
        PWR2spin->setDecimals(0);
        PWR2spin->setMinimum(800);
        PWR2spin->setMaximum(2800);
        PWR2spin->setSingleStep(10);
        PWR2spin->setValue(1800);

        gridLayout_13->addWidget(PWR2spin, 8, 2, 1, 1);

        PWR2CLCD = new QLCDNumber(layoutWidget_5);
        PWR2CLCD->setObjectName(QStringLiteral("PWR2CLCD"));
        PWR2CLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(PWR2CLCD, 8, 4, 1, 1);

        PWR3CheckBox = new QCheckBox(layoutWidget_5);
        PWR3CheckBox->setObjectName(QStringLiteral("PWR3CheckBox"));

        gridLayout_13->addWidget(PWR3CheckBox, 10, 0, 1, 1);

        PWR3spin = new QDoubleSpinBox(layoutWidget_5);
        PWR3spin->setObjectName(QStringLiteral("PWR3spin"));
        PWR3spin->setDecimals(0);
        PWR3spin->setMinimum(800);
        PWR3spin->setMaximum(2800);
        PWR3spin->setSingleStep(10);
        PWR3spin->setValue(1800);

        gridLayout_13->addWidget(PWR3spin, 10, 2, 1, 1);

        PWR3VLCD = new QLCDNumber(layoutWidget_5);
        PWR3VLCD->setObjectName(QStringLiteral("PWR3VLCD"));
        PWR3VLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(PWR3VLCD, 10, 3, 1, 1);

        PWR3CLCD = new QLCDNumber(layoutWidget_5);
        PWR3CLCD->setObjectName(QStringLiteral("PWR3CLCD"));
        PWR3CLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(PWR3CLCD, 10, 4, 1, 1);

        verticalSpacer = new QSpacerItem(20, 40, QSizePolicy::Minimum, QSizePolicy::Expanding);

        gridLayout_13->addItem(verticalSpacer, 24, 0, 1, 1);

        label_26 = new QLabel(layoutWidget_5);
        label_26->setObjectName(QStringLiteral("label_26"));
        QFont font1;
        font1.setBold(true);
        font1.setWeight(75);
        label_26->setFont(font1);

        gridLayout_13->addWidget(label_26, 0, 0, 1, 1);

        label_8 = new QLabel(layoutWidget_5);
        label_8->setObjectName(QStringLiteral("label_8"));
        QFont font2;
        font2.setBold(false);
        font2.setWeight(50);
        label_8->setFont(font2);
        label_8->setTextFormat(Qt::AutoText);

        gridLayout_13->addWidget(label_8, 11, 0, 1, 1);

        PWR0CheckBox = new QCheckBox(layoutWidget_5);
        PWR0CheckBox->setObjectName(QStringLiteral("PWR0CheckBox"));

        gridLayout_13->addWidget(PWR0CheckBox, 6, 0, 1, 1);

        label_9 = new QLabel(layoutWidget_5);
        label_9->setObjectName(QStringLiteral("label_9"));
        label_9->setFont(font1);

        gridLayout_13->addWidget(label_9, 12, 0, 1, 1);

        VSRC0spin = new QDoubleSpinBox(layoutWidget_5);
        VSRC0spin->setObjectName(QStringLiteral("VSRC0spin"));
        VSRC0spin->setDecimals(0);
        VSRC0spin->setMinimum(0);
        VSRC0spin->setMaximum(2000);
        VSRC0spin->setSingleStep(10);
        VSRC0spin->setValue(0);

        gridLayout_13->addWidget(VSRC0spin, 13, 2, 1, 1);

        label_10 = new QLabel(layoutWidget_5);
        label_10->setObjectName(QStringLiteral("label_10"));

        gridLayout_13->addWidget(label_10, 13, 0, 1, 1);

        VSRC2spin = new QDoubleSpinBox(layoutWidget_5);
        VSRC2spin->setObjectName(QStringLiteral("VSRC2spin"));
        VSRC2spin->setDecimals(0);
        VSRC2spin->setMinimum(0);
        VSRC2spin->setMaximum(2000);
        VSRC2spin->setSingleStep(10);
        VSRC2spin->setValue(0);

        gridLayout_13->addWidget(VSRC2spin, 15, 2, 1, 1);

        VSRC0VLCD = new QLCDNumber(layoutWidget_5);
        VSRC0VLCD->setObjectName(QStringLiteral("VSRC0VLCD"));
        VSRC0VLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(VSRC0VLCD, 13, 3, 1, 1);

        ISRC1spin = new QDoubleSpinBox(layoutWidget_5);
        ISRC1spin->setObjectName(QStringLiteral("ISRC1spin"));
        ISRC1spin->setDecimals(0);
        ISRC1spin->setMinimum(-1000);
        ISRC1spin->setMaximum(1000);
        ISRC1spin->setSingleStep(1);
        ISRC1spin->setValue(0);

        gridLayout_13->addWidget(ISRC1spin, 21, 2, 1, 1);

        label_12 = new QLabel(layoutWidget_5);
        label_12->setObjectName(QStringLiteral("label_12"));

        gridLayout_13->addWidget(label_12, 15, 0, 1, 1);

        ISRC0CLCD = new QLCDNumber(layoutWidget_5);
        ISRC0CLCD->setObjectName(QStringLiteral("ISRC0CLCD"));
        ISRC0CLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(ISRC0CLCD, 20, 4, 1, 1);

        label_24 = new QLabel(layoutWidget_5);
        label_24->setObjectName(QStringLiteral("label_24"));

        gridLayout_13->addWidget(label_24, 19, 2, 1, 1);

        VSRC0CLCD = new QLCDNumber(layoutWidget_5);
        VSRC0CLCD->setObjectName(QStringLiteral("VSRC0CLCD"));
        VSRC0CLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(VSRC0CLCD, 13, 4, 1, 1);

        label_14 = new QLabel(layoutWidget_5);
        label_14->setObjectName(QStringLiteral("label_14"));
        label_14->setFont(font1);

        gridLayout_13->addWidget(label_14, 19, 0, 1, 1);

        label_16 = new QLabel(layoutWidget_5);
        label_16->setObjectName(QStringLiteral("label_16"));

        gridLayout_13->addWidget(label_16, 21, 0, 1, 1);

        ISRC1CLCD = new QLCDNumber(layoutWidget_5);
        ISRC1CLCD->setObjectName(QStringLiteral("ISRC1CLCD"));
        ISRC1CLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(ISRC1CLCD, 21, 4, 1, 1);

        label_15 = new QLabel(layoutWidget_5);
        label_15->setObjectName(QStringLiteral("label_15"));

        gridLayout_13->addWidget(label_15, 20, 0, 1, 1);

        ISRC1VLCD = new QLCDNumber(layoutWidget_5);
        ISRC1VLCD->setObjectName(QStringLiteral("ISRC1VLCD"));
        ISRC1VLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(ISRC1VLCD, 21, 3, 1, 1);

        VSRC3spin = new QDoubleSpinBox(layoutWidget_5);
        VSRC3spin->setObjectName(QStringLiteral("VSRC3spin"));
        VSRC3spin->setDecimals(0);
        VSRC3spin->setMinimum(0);
        VSRC3spin->setMaximum(2000);
        VSRC3spin->setSingleStep(10);
        VSRC3spin->setValue(0);

        gridLayout_13->addWidget(VSRC3spin, 17, 2, 1, 1);

        VSRC1CLCD = new QLCDNumber(layoutWidget_5);
        VSRC1CLCD->setObjectName(QStringLiteral("VSRC1CLCD"));
        VSRC1CLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(VSRC1CLCD, 14, 4, 1, 1);

        VSRC3CLCD = new QLCDNumber(layoutWidget_5);
        VSRC3CLCD->setObjectName(QStringLiteral("VSRC3CLCD"));
        VSRC3CLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(VSRC3CLCD, 17, 4, 1, 1);

        VSRC2VLCD = new QLCDNumber(layoutWidget_5);
        VSRC2VLCD->setObjectName(QStringLiteral("VSRC2VLCD"));
        VSRC2VLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(VSRC2VLCD, 15, 3, 1, 1);

        label_13 = new QLabel(layoutWidget_5);
        label_13->setObjectName(QStringLiteral("label_13"));

        gridLayout_13->addWidget(label_13, 17, 0, 1, 1);

        ISRC0VLCD = new QLCDNumber(layoutWidget_5);
        ISRC0VLCD->setObjectName(QStringLiteral("ISRC0VLCD"));
        ISRC0VLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(ISRC0VLCD, 20, 3, 1, 1);

        ISRC0spin = new QDoubleSpinBox(layoutWidget_5);
        ISRC0spin->setObjectName(QStringLiteral("ISRC0spin"));
        ISRC0spin->setDecimals(0);
        ISRC0spin->setMinimum(-1000);
        ISRC0spin->setMaximum(1000);
        ISRC0spin->setSingleStep(1);
        ISRC0spin->setValue(0);

        gridLayout_13->addWidget(ISRC0spin, 20, 2, 1, 1);

        label_11 = new QLabel(layoutWidget_5);
        label_11->setObjectName(QStringLiteral("label_11"));

        gridLayout_13->addWidget(label_11, 14, 0, 1, 1);

        VSRC1VLCD = new QLCDNumber(layoutWidget_5);
        VSRC1VLCD->setObjectName(QStringLiteral("VSRC1VLCD"));
        VSRC1VLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(VSRC1VLCD, 14, 3, 1, 1);

        VSRC2CLCD = new QLCDNumber(layoutWidget_5);
        VSRC2CLCD->setObjectName(QStringLiteral("VSRC2CLCD"));
        VSRC2CLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(VSRC2CLCD, 15, 4, 1, 1);

        VSRC3VLCD = new QLCDNumber(layoutWidget_5);
        VSRC3VLCD->setObjectName(QStringLiteral("VSRC3VLCD"));
        VSRC3VLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(VSRC3VLCD, 17, 3, 1, 1);

        VSRC1spin = new QDoubleSpinBox(layoutWidget_5);
        VSRC1spin->setObjectName(QStringLiteral("VSRC1spin"));
        VSRC1spin->setDecimals(0);
        VSRC1spin->setMinimum(0);
        VSRC1spin->setMaximum(2000);
        VSRC1spin->setSingleStep(10);
        VSRC1spin->setValue(0);

        gridLayout_13->addWidget(VSRC1spin, 14, 2, 1, 1);

        PWR2VLCD = new QLCDNumber(layoutWidget_5);
        PWR2VLCD->setObjectName(QStringLiteral("PWR2VLCD"));
        PWR2VLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(PWR2VLCD, 8, 3, 1, 1);

        label_23 = new QLabel(layoutWidget_5);
        label_23->setObjectName(QStringLiteral("label_23"));

        gridLayout_13->addWidget(label_23, 0, 2, 1, 1);

        ISRC2VLCD = new QLCDNumber(layoutWidget_5);
        ISRC2VLCD->setObjectName(QStringLiteral("ISRC2VLCD"));
        ISRC2VLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(ISRC2VLCD, 22, 3, 1, 1);

        ISRC3spin = new QDoubleSpinBox(layoutWidget_5);
        ISRC3spin->setObjectName(QStringLiteral("ISRC3spin"));
        ISRC3spin->setDecimals(0);
        ISRC3spin->setMinimum(-1000);
        ISRC3spin->setMaximum(1000);
        ISRC3spin->setSingleStep(1);
        ISRC3spin->setValue(0);

        gridLayout_13->addWidget(ISRC3spin, 23, 2, 1, 1);

        ISRC2CLCD = new QLCDNumber(layoutWidget_5);
        ISRC2CLCD->setObjectName(QStringLiteral("ISRC2CLCD"));
        ISRC2CLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(ISRC2CLCD, 22, 4, 1, 1);

        ISRC3VLCD = new QLCDNumber(layoutWidget_5);
        ISRC3VLCD->setObjectName(QStringLiteral("ISRC3VLCD"));
        ISRC3VLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(ISRC3VLCD, 23, 3, 1, 1);

        label_18 = new QLabel(layoutWidget_5);
        label_18->setObjectName(QStringLiteral("label_18"));

        gridLayout_13->addWidget(label_18, 23, 0, 1, 1);

        ISRC3CLCD = new QLCDNumber(layoutWidget_5);
        ISRC3CLCD->setObjectName(QStringLiteral("ISRC3CLCD"));
        ISRC3CLCD->setSegmentStyle(QLCDNumber::Flat);

        gridLayout_13->addWidget(ISRC3CLCD, 23, 4, 1, 1);

        label_17 = new QLabel(layoutWidget_5);
        label_17->setObjectName(QStringLiteral("label_17"));

        gridLayout_13->addWidget(label_17, 22, 0, 1, 1);

        ISRC2spin = new QDoubleSpinBox(layoutWidget_5);
        ISRC2spin->setObjectName(QStringLiteral("ISRC2spin"));
        ISRC2spin->setDecimals(0);
        ISRC2spin->setMinimum(-1000);
        ISRC2spin->setMaximum(1000);
        ISRC2spin->setSingleStep(1);
        ISRC2spin->setValue(0);

        gridLayout_13->addWidget(ISRC2spin, 22, 2, 1, 1);

        PWRname_0 = new QLabel(layoutWidget_5);
        PWRname_0->setObjectName(QStringLiteral("PWRname_0"));

        gridLayout_13->addWidget(PWRname_0, 6, 1, 1, 1);

        PWRname_1 = new QLabel(layoutWidget_5);
        PWRname_1->setObjectName(QStringLiteral("PWRname_1"));

        gridLayout_13->addWidget(PWRname_1, 7, 1, 1, 1);

        PWRname_2 = new QLabel(layoutWidget_5);
        PWRname_2->setObjectName(QStringLiteral("PWRname_2"));

        gridLayout_13->addWidget(PWRname_2, 8, 1, 1, 1);

        PWRname_3 = new QLabel(layoutWidget_5);
        PWRname_3->setObjectName(QStringLiteral("PWRname_3"));

        gridLayout_13->addWidget(PWRname_3, 10, 1, 1, 1);

        VSRCname_0 = new QLabel(layoutWidget_5);
        VSRCname_0->setObjectName(QStringLiteral("VSRCname_0"));

        gridLayout_13->addWidget(VSRCname_0, 13, 1, 1, 1);

        VSRCname_1 = new QLabel(layoutWidget_5);
        VSRCname_1->setObjectName(QStringLiteral("VSRCname_1"));

        gridLayout_13->addWidget(VSRCname_1, 14, 1, 1, 1);

        VSRCname_2 = new QLabel(layoutWidget_5);
        VSRCname_2->setObjectName(QStringLiteral("VSRCname_2"));

        gridLayout_13->addWidget(VSRCname_2, 15, 1, 1, 1);

        VSRCname_3 = new QLabel(layoutWidget_5);
        VSRCname_3->setObjectName(QStringLiteral("VSRCname_3"));

        gridLayout_13->addWidget(VSRCname_3, 17, 1, 1, 1);

        ISRCname_0 = new QLabel(layoutWidget_5);
        ISRCname_0->setObjectName(QStringLiteral("ISRCname_0"));

        gridLayout_13->addWidget(ISRCname_0, 20, 1, 1, 1);

        ISRCname_1 = new QLabel(layoutWidget_5);
        ISRCname_1->setObjectName(QStringLiteral("ISRCname_1"));

        gridLayout_13->addWidget(ISRCname_1, 21, 1, 1, 1);

        ISRCname_2 = new QLabel(layoutWidget_5);
        ISRCname_2->setObjectName(QStringLiteral("ISRCname_2"));

        gridLayout_13->addWidget(ISRCname_2, 22, 1, 1, 1);

        ISRCname_3 = new QLabel(layoutWidget_5);
        ISRCname_3->setObjectName(QStringLiteral("ISRCname_3"));

        gridLayout_13->addWidget(ISRCname_3, 23, 1, 1, 1);

        label_69 = new QLabel(layoutWidget_5);
        label_69->setObjectName(QStringLiteral("label_69"));

        gridLayout_13->addWidget(label_69, 12, 4, 1, 1);

        label_70 = new QLabel(layoutWidget_5);
        label_70->setObjectName(QStringLiteral("label_70"));

        gridLayout_13->addWidget(label_70, 19, 4, 1, 1);

        label_71 = new QLabel(layoutWidget_5);
        label_71->setObjectName(QStringLiteral("label_71"));

        gridLayout_13->addWidget(label_71, 12, 3, 1, 1);

        label_72 = new QLabel(layoutWidget_5);
        label_72->setObjectName(QStringLiteral("label_72"));

        gridLayout_13->addWidget(label_72, 19, 3, 1, 1);

        label_25 = new QLabel(layoutWidget_5);
        label_25->setObjectName(QStringLiteral("label_25"));

        gridLayout_13->addWidget(label_25, 12, 2, 1, 1);

        CurrLimBox = new QDoubleSpinBox(layoutWidget_5);
        CurrLimBox->setObjectName(QStringLiteral("CurrLimBox"));
        CurrLimBox->setDecimals(0);
        CurrLimBox->setMaximum(200);
        CurrLimBox->setSingleStep(1);
        CurrLimBox->setValue(100);

        gridLayout_13->addWidget(CurrLimBox, 11, 4, 1, 1);

        checkBox = new QCheckBox(Seite_2);
        checkBox->setObjectName(QStringLiteral("checkBox"));
        checkBox->setGeometry(QRect(420, 110, 72, 18));
        tabWidget->addTab(Seite_2, QString());
        Keithley24xxTab = new QWidget();
        Keithley24xxTab->setObjectName(QStringLiteral("Keithley24xxTab"));
        measBtn = new QPushButton(Keithley24xxTab);
        measBtn->setObjectName(QStringLiteral("measBtn"));
        measBtn->setGeometry(QRect(40, 100, 131, 81));
        groupBox = new QGroupBox(Keithley24xxTab);
        groupBox->setObjectName(QStringLiteral("groupBox"));
        groupBox->setGeometry(QRect(10, 10, 171, 71));
        currBtn = new QRadioButton(groupBox);
        currBtn->setObjectName(QStringLiteral("currBtn"));
        currBtn->setGeometry(QRect(100, 30, 61, 18));
        voltageBtn = new QRadioButton(groupBox);
        voltageBtn->setObjectName(QStringLiteral("voltageBtn"));
        voltageBtn->setGeometry(QRect(20, 30, 61, 18));
        voltageBtn->setChecked(true);
        groupBox_2 = new QGroupBox(Keithley24xxTab);
        groupBox_2->setObjectName(QStringLiteral("groupBox_2"));
        groupBox_2->setGeometry(QRect(190, 10, 171, 71));
        onBtn = new QToolButton(groupBox_2);
        onBtn->setObjectName(QStringLiteral("onBtn"));
        onBtn->setGeometry(QRect(30, 20, 41, 31));
        onBtn->setCheckable(true);
        onBtn->setAutoExclusive(true);
        offBtn = new QToolButton(groupBox_2);
        offBtn->setObjectName(QStringLiteral("offBtn"));
        offBtn->setGeometry(QRect(100, 20, 41, 31));
        offBtn->setCheckable(true);
        offBtn->setChecked(true);
        offBtn->setAutoExclusive(true);
        setBtn = new QPushButton(Keithley24xxTab);
        setBtn->setObjectName(QStringLiteral("setBtn"));
        setBtn->setGeometry(QRect(40, 210, 131, 81));
        voltageLCD = new QLCDNumber(Keithley24xxTab);
        voltageLCD->setObjectName(QStringLiteral("voltageLCD"));
        voltageLCD->setGeometry(QRect(200, 100, 91, 31));
        QPalette palette;
        QBrush brush(QColor(85, 255, 0, 255));
        brush.setStyle(Qt::SolidPattern);
        palette.setBrush(QPalette::Active, QPalette::WindowText, brush);
        QBrush brush1(QColor(0, 0, 0, 255));
        brush1.setStyle(Qt::SolidPattern);
        palette.setBrush(QPalette::Active, QPalette::Button, brush1);
        palette.setBrush(QPalette::Active, QPalette::Light, brush1);
        palette.setBrush(QPalette::Active, QPalette::Midlight, brush1);
        palette.setBrush(QPalette::Active, QPalette::Dark, brush1);
        palette.setBrush(QPalette::Active, QPalette::Mid, brush1);
        palette.setBrush(QPalette::Active, QPalette::Text, brush1);
        palette.setBrush(QPalette::Active, QPalette::BrightText, brush1);
        palette.setBrush(QPalette::Active, QPalette::ButtonText, brush1);
        palette.setBrush(QPalette::Active, QPalette::Base, brush1);
        palette.setBrush(QPalette::Active, QPalette::Window, brush1);
        palette.setBrush(QPalette::Active, QPalette::AlternateBase, brush1);
        QBrush brush2(QColor(0, 255, 127, 255));
        brush2.setStyle(Qt::SolidPattern);
        palette.setBrush(QPalette::Active, QPalette::NoRole, brush2);
        palette.setBrush(QPalette::Inactive, QPalette::WindowText, brush);
        palette.setBrush(QPalette::Inactive, QPalette::Button, brush1);
        palette.setBrush(QPalette::Inactive, QPalette::Light, brush1);
        palette.setBrush(QPalette::Inactive, QPalette::Midlight, brush1);
        palette.setBrush(QPalette::Inactive, QPalette::Dark, brush1);
        palette.setBrush(QPalette::Inactive, QPalette::Mid, brush1);
        palette.setBrush(QPalette::Inactive, QPalette::Text, brush1);
        palette.setBrush(QPalette::Inactive, QPalette::BrightText, brush1);
        palette.setBrush(QPalette::Inactive, QPalette::ButtonText, brush1);
        palette.setBrush(QPalette::Inactive, QPalette::Base, brush1);
        palette.setBrush(QPalette::Inactive, QPalette::Window, brush1);
        palette.setBrush(QPalette::Inactive, QPalette::AlternateBase, brush1);
        QBrush brush3(QColor(170, 85, 255, 255));
        brush3.setStyle(Qt::SolidPattern);
        palette.setBrush(QPalette::Inactive, QPalette::NoRole, brush3);
        palette.setBrush(QPalette::Disabled, QPalette::WindowText, brush1);
        palette.setBrush(QPalette::Disabled, QPalette::Button, brush1);
        palette.setBrush(QPalette::Disabled, QPalette::Light, brush1);
        palette.setBrush(QPalette::Disabled, QPalette::Midlight, brush1);
        palette.setBrush(QPalette::Disabled, QPalette::Dark, brush1);
        palette.setBrush(QPalette::Disabled, QPalette::Mid, brush1);
        palette.setBrush(QPalette::Disabled, QPalette::Text, brush1);
        palette.setBrush(QPalette::Disabled, QPalette::BrightText, brush1);
        palette.setBrush(QPalette::Disabled, QPalette::ButtonText, brush1);
        palette.setBrush(QPalette::Disabled, QPalette::Base, brush1);
        palette.setBrush(QPalette::Disabled, QPalette::Window, brush1);
        palette.setBrush(QPalette::Disabled, QPalette::AlternateBase, brush1);
        QBrush brush4(QColor(85, 85, 255, 255));
        brush4.setStyle(Qt::SolidPattern);
        palette.setBrush(QPalette::Disabled, QPalette::NoRole, brush4);
        voltageLCD->setPalette(palette);
        voltageLCD->setAutoFillBackground(true);
        voltageLCD->setDigitCount(6);
        voltageLCD->setSegmentStyle(QLCDNumber::Flat);
        currentLCD = new QLCDNumber(Keithley24xxTab);
        currentLCD->setObjectName(QStringLiteral("currentLCD"));
        currentLCD->setGeometry(QRect(200, 150, 91, 31));
        QPalette palette1;
        palette1.setBrush(QPalette::Active, QPalette::WindowText, brush);
        palette1.setBrush(QPalette::Active, QPalette::Button, brush1);
        palette1.setBrush(QPalette::Active, QPalette::Light, brush1);
        palette1.setBrush(QPalette::Active, QPalette::Midlight, brush1);
        palette1.setBrush(QPalette::Active, QPalette::Dark, brush1);
        palette1.setBrush(QPalette::Active, QPalette::Mid, brush1);
        palette1.setBrush(QPalette::Active, QPalette::Text, brush1);
        palette1.setBrush(QPalette::Active, QPalette::BrightText, brush1);
        palette1.setBrush(QPalette::Active, QPalette::ButtonText, brush1);
        palette1.setBrush(QPalette::Active, QPalette::Base, brush1);
        palette1.setBrush(QPalette::Active, QPalette::Window, brush1);
        palette1.setBrush(QPalette::Active, QPalette::AlternateBase, brush1);
        palette1.setBrush(QPalette::Active, QPalette::NoRole, brush2);
        palette1.setBrush(QPalette::Inactive, QPalette::WindowText, brush);
        palette1.setBrush(QPalette::Inactive, QPalette::Button, brush1);
        palette1.setBrush(QPalette::Inactive, QPalette::Light, brush1);
        palette1.setBrush(QPalette::Inactive, QPalette::Midlight, brush1);
        palette1.setBrush(QPalette::Inactive, QPalette::Dark, brush1);
        palette1.setBrush(QPalette::Inactive, QPalette::Mid, brush1);
        palette1.setBrush(QPalette::Inactive, QPalette::Text, brush1);
        palette1.setBrush(QPalette::Inactive, QPalette::BrightText, brush1);
        palette1.setBrush(QPalette::Inactive, QPalette::ButtonText, brush1);
        palette1.setBrush(QPalette::Inactive, QPalette::Base, brush1);
        palette1.setBrush(QPalette::Inactive, QPalette::Window, brush1);
        palette1.setBrush(QPalette::Inactive, QPalette::AlternateBase, brush1);
        palette1.setBrush(QPalette::Inactive, QPalette::NoRole, brush3);
        palette1.setBrush(QPalette::Disabled, QPalette::WindowText, brush1);
        palette1.setBrush(QPalette::Disabled, QPalette::Button, brush1);
        palette1.setBrush(QPalette::Disabled, QPalette::Light, brush1);
        palette1.setBrush(QPalette::Disabled, QPalette::Midlight, brush1);
        palette1.setBrush(QPalette::Disabled, QPalette::Dark, brush1);
        palette1.setBrush(QPalette::Disabled, QPalette::Mid, brush1);
        palette1.setBrush(QPalette::Disabled, QPalette::Text, brush1);
        palette1.setBrush(QPalette::Disabled, QPalette::BrightText, brush1);
        palette1.setBrush(QPalette::Disabled, QPalette::ButtonText, brush1);
        palette1.setBrush(QPalette::Disabled, QPalette::Base, brush1);
        palette1.setBrush(QPalette::Disabled, QPalette::Window, brush1);
        palette1.setBrush(QPalette::Disabled, QPalette::AlternateBase, brush1);
        palette1.setBrush(QPalette::Disabled, QPalette::NoRole, brush4);
        currentLCD->setPalette(palette1);
        currentLCD->setAutoFillBackground(true);
        currentLCD->setDigitCount(6);
        currentLCD->setSegmentStyle(QLCDNumber::Flat);
        label_3 = new QLabel(Keithley24xxTab);
        label_3->setObjectName(QStringLiteral("label_3"));
        label_3->setGeometry(QRect(300, 110, 46, 14));
        QFont font3;
        font3.setPointSize(11);
        font3.setBold(true);
        font3.setWeight(75);
        label_3->setFont(font3);
        label_4 = new QLabel(Keithley24xxTab);
        label_4->setObjectName(QStringLiteral("label_4"));
        label_4->setGeometry(QRect(300, 160, 61, 16));
        label_4->setFont(font3);
        voltageVal = new QDoubleSpinBox(Keithley24xxTab);
        voltageVal->setObjectName(QStringLiteral("voltageVal"));
        voltageVal->setGeometry(QRect(200, 210, 91, 31));
        QFont font4;
        font4.setPointSize(12);
        font4.setBold(true);
        font4.setWeight(75);
        voltageVal->setFont(font4);
        voltageVal->setDecimals(4);
        voltageVal->setSingleStep(0.1);
        currentVal = new QDoubleSpinBox(Keithley24xxTab);
        currentVal->setObjectName(QStringLiteral("currentVal"));
        currentVal->setEnabled(false);
        currentVal->setGeometry(QRect(200, 260, 91, 31));
        currentVal->setFont(font4);
        currentVal->setDecimals(4);
        currentVal->setSingleStep(0.1);
        label_5 = new QLabel(Keithley24xxTab);
        label_5->setObjectName(QStringLiteral("label_5"));
        label_5->setGeometry(QRect(300, 220, 46, 14));
        label_5->setFont(font3);
        label_6 = new QLabel(Keithley24xxTab);
        label_6->setObjectName(QStringLiteral("label_6"));
        label_6->setGeometry(QRect(300, 270, 61, 16));
        label_6->setFont(font3);
        tabWidget->addTab(Keithley24xxTab, QString());
        sysTab = new QWidget();
        sysTab->setObjectName(QStringLiteral("sysTab"));
        confFPGAButton = new QPushButton(sysTab);
        confFPGAButton->setObjectName(QStringLiteral("confFPGAButton"));
        confFPGAButton->setGeometry(QRect(270, 20, 75, 24));
        fileDialogButton = new QToolButton(sysTab);
        fileDialogButton->setObjectName(QStringLiteral("fileDialogButton"));
        fileDialogButton->setGeometry(QRect(220, 20, 25, 20));
        fileLineEdit = new QLineEdit(sysTab);
        fileLineEdit->setObjectName(QStringLiteral("fileLineEdit"));
        fileLineEdit->setGeometry(QRect(20, 20, 201, 20));
        tabWidget->addTab(sysTab, QString());
        GPIBTab = new QWidget();
        GPIBTab->setObjectName(QStringLiteral("GPIBTab"));
        textBrowser = new QTextBrowser(GPIBTab);
        textBrowser->setObjectName(QStringLiteral("textBrowser"));
        textBrowser->setGeometry(QRect(10, 10, 361, 161));
        refreshListBtn = new QPushButton(GPIBTab);
        refreshListBtn->setObjectName(QStringLiteral("refreshListBtn"));
        refreshListBtn->setGeometry(QRect(270, 180, 101, 23));
        sendReceiveBtn = new QPushButton(GPIBTab);
        sendReceiveBtn->setObjectName(QStringLiteral("sendReceiveBtn"));
        sendReceiveBtn->setGeometry(QRect(270, 270, 101, 23));
        deviceIdEdit = new QLineEdit(GPIBTab);
        deviceIdEdit->setObjectName(QStringLiteral("deviceIdEdit"));
        deviceIdEdit->setGeometry(QRect(10, 240, 41, 20));
        label = new QLabel(GPIBTab);
        label->setObjectName(QStringLiteral("label"));
        label->setGeometry(QRect(10, 220, 46, 14));
        label_2 = new QLabel(GPIBTab);
        label_2->setObjectName(QStringLiteral("label_2"));
        label_2->setGeometry(QRect(60, 220, 46, 14));
        commandEdit = new QLineEdit(GPIBTab);
        commandEdit->setObjectName(QStringLiteral("commandEdit"));
        commandEdit->setGeometry(QRect(60, 240, 201, 20));
        sendBtn = new QPushButton(GPIBTab);
        sendBtn->setObjectName(QStringLiteral("sendBtn"));
        sendBtn->setGeometry(QRect(270, 240, 101, 23));
        clearGPIBBtn = new QPushButton(GPIBTab);
        clearGPIBBtn->setObjectName(QStringLiteral("clearGPIBBtn"));
        clearGPIBBtn->setGeometry(QRect(270, 300, 101, 23));
        tabWidget->addTab(GPIBTab, QString());
        statusLabel = new QLabel(MainForm);
        statusLabel->setObjectName(QStringLiteral("statusLabel"));
        statusLabel->setGeometry(QRect(10, 650, 491, 16));

        retranslateUi(MainForm);
        QObject::connect(refreshListBtn, SIGNAL(clicked()), MainForm, SLOT(refreshGPIBList()));
        QObject::connect(confFPGAButton, SIGNAL(clicked()), MainForm, SLOT(confFPGA()));
        QObject::connect(fileDialogButton, SIGNAL(clicked()), MainForm, SLOT(openFileDialog()));
        QObject::connect(sendBtn, SIGNAL(clicked()), MainForm, SLOT(sendGPIB()));
        QObject::connect(sendReceiveBtn, SIGNAL(clicked()), MainForm, SLOT(sendReceiveGPIB()));
        QObject::connect(clearGPIBBtn, SIGNAL(clicked()), MainForm, SLOT(clearGPIB()));
        QObject::connect(currBtn, SIGNAL(toggled(bool)), currentVal, SLOT(setEnabled(bool)));
        QObject::connect(voltageBtn, SIGNAL(toggled(bool)), voltageVal, SLOT(setEnabled(bool)));
        QObject::connect(offBtn, SIGNAL(clicked()), MainForm, SLOT(setSMUoff()));
        QObject::connect(onBtn, SIGNAL(clicked()), MainForm, SLOT(setSMUon()));
        QObject::connect(currBtn, SIGNAL(clicked()), MainForm, SLOT(setSMUCout()));
        QObject::connect(voltageBtn, SIGNAL(clicked()), MainForm, SLOT(setSMUVout()));
        QObject::connect(measBtn, SIGNAL(clicked()), MainForm, SLOT(getSMUMeas()));
        QObject::connect(setBtn, SIGNAL(clicked()), MainForm, SLOT(setSMUval()));
        QObject::connect(calBtn, SIGNAL(clicked()), MainForm, SLOT(calibrate()));
        QObject::connect(refreshDCSButton, SIGNAL(clicked()), MainForm, SLOT(updateMeasurements()));
        QObject::connect(chSelBox, SIGNAL(currentIndexChanged(int)), MainForm, SLOT(selectSMU()));
        QObject::connect(updateEEPROMBtn, SIGNAL(clicked()), MainForm, SLOT(updateEEPROM()));
        QObject::connect(dumpEEPROMBtn, SIGNAL(clicked()), MainForm, SLOT(dumpEEPROM()));
        QObject::connect(IdNumBox, SIGNAL(editingFinished()), MainForm, SLOT(setId()));
        QObject::connect(checkBox, SIGNAL(clicked(bool)), MainForm, SLOT(enableTimer(bool)));

        tabWidget->setCurrentIndex(1);


        QMetaObject::connectSlotsByName(MainForm);
    } // setupUi

    void retranslateUi(QWidget *MainForm)
    {
        MainForm->setWindowTitle(QApplication::translate("MainForm", "General Purpose Analog Card (GPAC)", 0));
        calBtn->setText(QApplication::translate("MainForm", "Calibrate", 0));
        chSelBox->clear();
        chSelBox->insertItems(0, QStringList()
         << QApplication::translate("MainForm", "CH1", 0)
         << QApplication::translate("MainForm", "CH2", 0)
         << QApplication::translate("MainForm", "CH3", 0)
         << QApplication::translate("MainForm", "CH4", 0)
        );
        updateEEPROMBtn->setText(QApplication::translate("MainForm", "Write EEPROM", 0));
        dumpEEPROMBtn->setText(QApplication::translate("MainForm", "Read EEPROM", 0));
        label_7->setText(QApplication::translate("MainForm", "Id:", 0));
        tabWidget->setTabText(tabWidget->indexOf(Seite), QApplication::translate("MainForm", "Calibration", 0));
        refreshDCSButton->setText(QApplication::translate("MainForm", "Update", 0));
        PWR1CheckBox->setText(QApplication::translate("MainForm", "PWR 1", 0));
        label_67->setText(QApplication::translate("MainForm", "Voltage [mV]", 0));
        label_68->setText(QApplication::translate("MainForm", "Current [mA]", 0));
        PWR2CheckBox->setText(QApplication::translate("MainForm", "PWR 2", 0));
        PWR3CheckBox->setText(QApplication::translate("MainForm", "PWR 3", 0));
        label_26->setText(QApplication::translate("MainForm", "Power Supplies", 0));
        label_8->setText(QApplication::translate("MainForm", "Current Limit [mA]", 0));
        PWR0CheckBox->setText(QApplication::translate("MainForm", "PWR 0", 0));
        label_9->setText(QApplication::translate("MainForm", "Voltage Sources", 0));
        label_10->setText(QApplication::translate("MainForm", "VSRC 0", 0));
        label_12->setText(QApplication::translate("MainForm", "VSRC 2", 0));
        label_24->setText(QApplication::translate("MainForm", "Current set [\302\265A]", 0));
        label_14->setText(QApplication::translate("MainForm", "Current Sources", 0));
        label_16->setText(QApplication::translate("MainForm", "ISRC 1", 0));
        label_15->setText(QApplication::translate("MainForm", "ISRC 0", 0));
        label_13->setText(QApplication::translate("MainForm", "VSRC 3", 0));
        label_11->setText(QApplication::translate("MainForm", "VSRC 1", 0));
        label_23->setText(QApplication::translate("MainForm", "Voltage set [mV]", 0));
        label_18->setText(QApplication::translate("MainForm", "ISRC 3", 0));
        label_17->setText(QApplication::translate("MainForm", "ISRC 2", 0));
        PWRname_0->setText(QString());
        PWRname_1->setText(QString());
        PWRname_2->setText(QString());
        PWRname_3->setText(QString());
        VSRCname_0->setText(QString());
        VSRCname_1->setText(QString());
        VSRCname_2->setText(QString());
        VSRCname_3->setText(QString());
        ISRCname_0->setText(QString());
        ISRCname_1->setText(QString());
        ISRCname_2->setText(QString());
        ISRCname_3->setText(QString());
        label_69->setText(QApplication::translate("MainForm", "Current [\302\265A]", 0));
        label_70->setText(QApplication::translate("MainForm", "Current [\302\265A]", 0));
        label_71->setText(QApplication::translate("MainForm", "Voltage [mV]", 0));
        label_72->setText(QApplication::translate("MainForm", "Voltage [mV]", 0));
        label_25->setText(QApplication::translate("MainForm", "Voltage set [mV]", 0));
        checkBox->setText(QApplication::translate("MainForm", "continuous", 0));
        tabWidget->setTabText(tabWidget->indexOf(Seite_2), QApplication::translate("MainForm", "Test", 0));
        measBtn->setText(QApplication::translate("MainForm", "Measure", 0));
        groupBox->setTitle(QApplication::translate("MainForm", "Source select", 0));
        currBtn->setText(QApplication::translate("MainForm", "Current", 0));
        voltageBtn->setText(QApplication::translate("MainForm", "Voltage", 0));
        groupBox_2->setTitle(QApplication::translate("MainForm", "Output", 0));
        onBtn->setText(QApplication::translate("MainForm", "On", 0));
        offBtn->setText(QApplication::translate("MainForm", "Off", 0));
        setBtn->setText(QApplication::translate("MainForm", "Set", 0));
        label_3->setText(QApplication::translate("MainForm", "Volt", 0));
        label_4->setText(QApplication::translate("MainForm", "Ampere", 0));
        label_5->setText(QApplication::translate("MainForm", "Volt", 0));
        label_6->setText(QApplication::translate("MainForm", "Ampere", 0));
        tabWidget->setTabText(tabWidget->indexOf(Keithley24xxTab), QApplication::translate("MainForm", "Keithley 24xx", 0));
        confFPGAButton->setText(QApplication::translate("MainForm", "Conf. FPGA", 0));
        fileDialogButton->setText(QApplication::translate("MainForm", "...", 0));
        tabWidget->setTabText(tabWidget->indexOf(sysTab), QApplication::translate("MainForm", "System Configuration", 0));
        refreshListBtn->setText(QApplication::translate("MainForm", "Update device list", 0));
        sendReceiveBtn->setText(QApplication::translate("MainForm", "Send && Receive", 0));
        label->setText(QApplication::translate("MainForm", "ADDR", 0));
        label_2->setText(QApplication::translate("MainForm", "Command", 0));
        sendBtn->setText(QApplication::translate("MainForm", "Send", 0));
        clearGPIBBtn->setText(QApplication::translate("MainForm", "Clear Device", 0));
        tabWidget->setTabText(tabWidget->indexOf(GPIBTab), QApplication::translate("MainForm", "GPIB Devices", 0));
        statusLabel->setText(QApplication::translate("MainForm", "TextLabel", 0));
    } // retranslateUi

};

namespace Ui {
    class MainForm: public Ui_MainForm {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_MAINFORM_H
