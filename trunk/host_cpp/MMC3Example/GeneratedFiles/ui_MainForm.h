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
#include <QtWidgets/QGridLayout>
#include <QtWidgets/QGroupBox>
#include <QtWidgets/QHeaderView>
#include <QtWidgets/QLCDNumber>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMenu>
#include <QtWidgets/QMenuBar>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QStatusBar>
#include <QtWidgets/QTabWidget>
#include <QtWidgets/QToolButton>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_MainForm
{
public:
    QWidget *centralwidget;
    QTabWidget *tabWidget;
    QWidget *sysTab;
    QGroupBox *groupBox;
    QLineEdit *fileLineEdit;
    QPushButton *confFPGAButton;
    QToolButton *fileDialogButton;
    QGroupBox *groupBox_2;
    QLineEdit *writeDataLine;
    QLineEdit *readDataLine;
    QLineEdit *addLine;
    QPushButton *writeBtn;
    QPushButton *readBtn;
    QLabel *label;
    QGroupBox *groupBox_3;
    QWidget *gridLayoutWidget;
    QGridLayout *gridLayout;
    QLabel *label_3;
    QCheckBox *checkBoxEnC;
    QCheckBox *checkBoxEnB;
    QLabel *label_2;
    QCheckBox *checkBoxEnA;
    QCheckBox *checkBoxEnD;
    QLabel *label_4;
    QLCDNumber *lcdNumberAV;
    QLCDNumber *lcdNumberAC;
    QLCDNumber *lcdNumberBV;
    QLCDNumber *lcdNumberBC;
    QLCDNumber *lcdNumberCV;
    QLCDNumber *lcdNumberCC;
    QLCDNumber *lcdNumberDV;
    QLCDNumber *lcdNumberDC;
    QPushButton *measureBtn;
    QMenuBar *menubar;
    QMenu *menuMenu;
    QStatusBar *statusbar;

    void setupUi(QMainWindow *MainForm)
    {
        if (MainForm->objectName().isEmpty())
            MainForm->setObjectName(QStringLiteral("MainForm"));
        MainForm->resize(409, 417);
        QSizePolicy sizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
        sizePolicy.setHorizontalStretch(0);
        sizePolicy.setVerticalStretch(0);
        sizePolicy.setHeightForWidth(MainForm->sizePolicy().hasHeightForWidth());
        MainForm->setSizePolicy(sizePolicy);
        QIcon icon;
        icon.addFile(QStringLiteral("resources/silab.ico"), QSize(), QIcon::Normal, QIcon::Off);
        MainForm->setWindowIcon(icon);
        centralwidget = new QWidget(MainForm);
        centralwidget->setObjectName(QStringLiteral("centralwidget"));
        tabWidget = new QTabWidget(centralwidget);
        tabWidget->setObjectName(QStringLiteral("tabWidget"));
        tabWidget->setGeometry(QRect(10, 10, 391, 361));
        sizePolicy.setHeightForWidth(tabWidget->sizePolicy().hasHeightForWidth());
        tabWidget->setSizePolicy(sizePolicy);
        tabWidget->setMinimumSize(QSize(391, 361));
        tabWidget->setBaseSize(QSize(391, 361));
        sysTab = new QWidget();
        sysTab->setObjectName(QStringLiteral("sysTab"));
        groupBox = new QGroupBox(sysTab);
        groupBox->setObjectName(QStringLiteral("groupBox"));
        groupBox->setGeometry(QRect(10, 10, 361, 80));
        fileLineEdit = new QLineEdit(groupBox);
        fileLineEdit->setObjectName(QStringLiteral("fileLineEdit"));
        fileLineEdit->setGeometry(QRect(10, 30, 231, 20));
        confFPGAButton = new QPushButton(groupBox);
        confFPGAButton->setObjectName(QStringLiteral("confFPGAButton"));
        confFPGAButton->setGeometry(QRect(280, 30, 75, 23));
        fileDialogButton = new QToolButton(groupBox);
        fileDialogButton->setObjectName(QStringLiteral("fileDialogButton"));
        fileDialogButton->setGeometry(QRect(250, 30, 25, 23));
        groupBox_2 = new QGroupBox(sysTab);
        groupBox_2->setObjectName(QStringLiteral("groupBox_2"));
        groupBox_2->setGeometry(QRect(10, 100, 121, 111));
        writeDataLine = new QLineEdit(groupBox_2);
        writeDataLine->setObjectName(QStringLiteral("writeDataLine"));
        writeDataLine->setGeometry(QRect(70, 50, 41, 20));
        readDataLine = new QLineEdit(groupBox_2);
        readDataLine->setObjectName(QStringLiteral("readDataLine"));
        readDataLine->setGeometry(QRect(70, 80, 41, 20));
        readDataLine->setReadOnly(true);
        addLine = new QLineEdit(groupBox_2);
        addLine->setObjectName(QStringLiteral("addLine"));
        addLine->setEnabled(true);
        addLine->setGeometry(QRect(50, 20, 61, 20));
        addLine->setReadOnly(true);
        writeBtn = new QPushButton(groupBox_2);
        writeBtn->setObjectName(QStringLiteral("writeBtn"));
        writeBtn->setGeometry(QRect(10, 50, 41, 23));
        readBtn = new QPushButton(groupBox_2);
        readBtn->setObjectName(QStringLiteral("readBtn"));
        readBtn->setGeometry(QRect(10, 80, 41, 23));
        label = new QLabel(groupBox_2);
        label->setObjectName(QStringLiteral("label"));
        label->setGeometry(QRect(10, 20, 31, 16));
        groupBox_3 = new QGroupBox(sysTab);
        groupBox_3->setObjectName(QStringLiteral("groupBox_3"));
        groupBox_3->setGeometry(QRect(140, 100, 231, 211));
        gridLayoutWidget = new QWidget(groupBox_3);
        gridLayoutWidget->setObjectName(QStringLiteral("gridLayoutWidget"));
        gridLayoutWidget->setGeometry(QRect(10, 20, 211, 131));
        gridLayout = new QGridLayout(gridLayoutWidget);
        gridLayout->setObjectName(QStringLiteral("gridLayout"));
        gridLayout->setHorizontalSpacing(11);
        gridLayout->setContentsMargins(0, 0, 0, 0);
        label_3 = new QLabel(gridLayoutWidget);
        label_3->setObjectName(QStringLiteral("label_3"));

        gridLayout->addWidget(label_3, 0, 1, 1, 1);

        checkBoxEnC = new QCheckBox(gridLayoutWidget);
        checkBoxEnC->setObjectName(QStringLiteral("checkBoxEnC"));
        checkBoxEnC->setLayoutDirection(Qt::LeftToRight);

        gridLayout->addWidget(checkBoxEnC, 3, 0, 1, 1);

        checkBoxEnB = new QCheckBox(gridLayoutWidget);
        checkBoxEnB->setObjectName(QStringLiteral("checkBoxEnB"));
        checkBoxEnB->setLayoutDirection(Qt::LeftToRight);

        gridLayout->addWidget(checkBoxEnB, 2, 0, 1, 1);

        label_2 = new QLabel(gridLayoutWidget);
        label_2->setObjectName(QStringLiteral("label_2"));

        gridLayout->addWidget(label_2, 0, 0, 1, 1);

        checkBoxEnA = new QCheckBox(gridLayoutWidget);
        checkBoxEnA->setObjectName(QStringLiteral("checkBoxEnA"));
        checkBoxEnA->setLayoutDirection(Qt::LeftToRight);

        gridLayout->addWidget(checkBoxEnA, 1, 0, 1, 1);

        checkBoxEnD = new QCheckBox(gridLayoutWidget);
        checkBoxEnD->setObjectName(QStringLiteral("checkBoxEnD"));
        checkBoxEnD->setLayoutDirection(Qt::LeftToRight);

        gridLayout->addWidget(checkBoxEnD, 4, 0, 1, 1);

        label_4 = new QLabel(gridLayoutWidget);
        label_4->setObjectName(QStringLiteral("label_4"));

        gridLayout->addWidget(label_4, 0, 2, 1, 1);

        lcdNumberAV = new QLCDNumber(gridLayoutWidget);
        lcdNumberAV->setObjectName(QStringLiteral("lcdNumberAV"));

        gridLayout->addWidget(lcdNumberAV, 1, 1, 1, 1);

        lcdNumberAC = new QLCDNumber(gridLayoutWidget);
        lcdNumberAC->setObjectName(QStringLiteral("lcdNumberAC"));

        gridLayout->addWidget(lcdNumberAC, 1, 2, 1, 1);

        lcdNumberBV = new QLCDNumber(gridLayoutWidget);
        lcdNumberBV->setObjectName(QStringLiteral("lcdNumberBV"));

        gridLayout->addWidget(lcdNumberBV, 2, 1, 1, 1);

        lcdNumberBC = new QLCDNumber(gridLayoutWidget);
        lcdNumberBC->setObjectName(QStringLiteral("lcdNumberBC"));

        gridLayout->addWidget(lcdNumberBC, 2, 2, 1, 1);

        lcdNumberCV = new QLCDNumber(gridLayoutWidget);
        lcdNumberCV->setObjectName(QStringLiteral("lcdNumberCV"));

        gridLayout->addWidget(lcdNumberCV, 3, 1, 1, 1);

        lcdNumberCC = new QLCDNumber(gridLayoutWidget);
        lcdNumberCC->setObjectName(QStringLiteral("lcdNumberCC"));

        gridLayout->addWidget(lcdNumberCC, 3, 2, 1, 1);

        lcdNumberDV = new QLCDNumber(gridLayoutWidget);
        lcdNumberDV->setObjectName(QStringLiteral("lcdNumberDV"));

        gridLayout->addWidget(lcdNumberDV, 4, 1, 1, 1);

        lcdNumberDC = new QLCDNumber(gridLayoutWidget);
        lcdNumberDC->setObjectName(QStringLiteral("lcdNumberDC"));

        gridLayout->addWidget(lcdNumberDC, 4, 2, 1, 1);

        measureBtn = new QPushButton(groupBox_3);
        measureBtn->setObjectName(QStringLiteral("measureBtn"));
        measureBtn->setGeometry(QRect(80, 162, 141, 31));
        tabWidget->addTab(sysTab, QString());
        MainForm->setCentralWidget(centralwidget);
        menubar = new QMenuBar(MainForm);
        menubar->setObjectName(QStringLiteral("menubar"));
        menubar->setGeometry(QRect(0, 0, 409, 21));
        menuMenu = new QMenu(menubar);
        menuMenu->setObjectName(QStringLiteral("menuMenu"));
        MainForm->setMenuBar(menubar);
        statusbar = new QStatusBar(MainForm);
        statusbar->setObjectName(QStringLiteral("statusbar"));
        MainForm->setStatusBar(statusbar);

        menubar->addAction(menuMenu->menuAction());

        retranslateUi(MainForm);
        QObject::connect(readBtn, SIGNAL(clicked()), MainForm, SLOT(readClicked()));
        QObject::connect(writeBtn, SIGNAL(clicked()), MainForm, SLOT(writeClicked()));
        QObject::connect(confFPGAButton, SIGNAL(clicked()), MainForm, SLOT(confFPGA()));
        QObject::connect(fileDialogButton, SIGNAL(clicked()), MainForm, SLOT(openFileDialog()));

        tabWidget->setCurrentIndex(0);


        QMetaObject::connectSlotsByName(MainForm);
    } // setupUi

    void retranslateUi(QMainWindow *MainForm)
    {
        MainForm->setWindowTitle(QApplication::translate("MainForm", "USB Application Example", 0));
        groupBox->setTitle(QApplication::translate("MainForm", "FPGA firmware", 0));
        confFPGAButton->setText(QApplication::translate("MainForm", "Conf. FPGA", 0));
        fileDialogButton->setText(QApplication::translate("MainForm", "...", 0));
        groupBox_2->setTitle(QApplication::translate("MainForm", "GPIO", 0));
        writeDataLine->setText(QApplication::translate("MainForm", "0x00", 0));
        addLine->setText(QString());
        writeBtn->setText(QApplication::translate("MainForm", "Write", 0));
        readBtn->setText(QApplication::translate("MainForm", "Read", 0));
        label->setText(QApplication::translate("MainForm", "Name", 0));
        groupBox_3->setTitle(QApplication::translate("MainForm", "Power Channels", 0));
        label_3->setText(QApplication::translate("MainForm", "Voltage [V]", 0));
        checkBoxEnC->setText(QApplication::translate("MainForm", "C", 0));
        checkBoxEnB->setText(QApplication::translate("MainForm", "B", 0));
        label_2->setText(QApplication::translate("MainForm", "Enable", 0));
        checkBoxEnA->setText(QApplication::translate("MainForm", "A", 0));
        checkBoxEnD->setText(QApplication::translate("MainForm", "D", 0));
        label_4->setText(QApplication::translate("MainForm", "Current [A]", 0));
        measureBtn->setText(QApplication::translate("MainForm", "Measure", 0));
        tabWidget->setTabText(tabWidget->indexOf(sysTab), QApplication::translate("MainForm", "Test", 0));
        menuMenu->setTitle(QApplication::translate("MainForm", "Menu", 0));
    } // retranslateUi

};

namespace Ui {
    class MainForm: public Ui_MainForm {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_MAINFORM_H
