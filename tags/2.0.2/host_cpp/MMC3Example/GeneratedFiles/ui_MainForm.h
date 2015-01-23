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
#include <QtWidgets/QDoubleSpinBox>
#include <QtWidgets/QGridLayout>
#include <QtWidgets/QGroupBox>
#include <QtWidgets/QHeaderView>
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
    QWidget *pwrTab;
    QPushButton *measureBtn;
    QWidget *gridLayoutWidget;
    QGridLayout *gridLayout;
    QDoubleSpinBox *currLimCSpinBox;
    QDoubleSpinBox *currLimBSpinBox;
    QDoubleSpinBox *currLimDSpinBox;
    QLabel *label_3;
    QCheckBox *checkBoxEnC;
    QCheckBox *checkBoxEnB;
    QLabel *label_2;
    QCheckBox *checkBoxEnA;
    QLabel *label_4;
    QLabel *lcdNumberAV;
    QLabel *lcdNumberBV;
    QLabel *lcdNumberCV;
    QLabel *lcdNumberDV;
    QLabel *lcdNumberAC;
    QLabel *lcdNumberBC;
    QLabel *lcdNumberCC;
    QLabel *lcdNumberDC;
    QCheckBox *checkBoxEnD;
    QLabel *label_5;
    QDoubleSpinBox *currLimASpinBox;
    QPushButton *rstPwrBtn;
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
        tabWidget->addTab(sysTab, QString());
        pwrTab = new QWidget();
        pwrTab->setObjectName(QStringLiteral("pwrTab"));
        measureBtn = new QPushButton(pwrTab);
        measureBtn->setObjectName(QStringLiteral("measureBtn"));
        measureBtn->setGeometry(QRect(90, 170, 121, 31));
        gridLayoutWidget = new QWidget(pwrTab);
        gridLayoutWidget->setObjectName(QStringLiteral("gridLayoutWidget"));
        gridLayoutWidget->setGeometry(QRect(10, 20, 276, 139));
        gridLayout = new QGridLayout(gridLayoutWidget);
        gridLayout->setObjectName(QStringLiteral("gridLayout"));
        gridLayout->setHorizontalSpacing(11);
        gridLayout->setContentsMargins(0, 0, 0, 0);
        currLimCSpinBox = new QDoubleSpinBox(gridLayoutWidget);
        currLimCSpinBox->setObjectName(QStringLiteral("currLimCSpinBox"));
        QFont font;
        font.setFamily(QStringLiteral("Consolas"));
        font.setPointSize(12);
        font.setBold(true);
        font.setWeight(75);
        currLimCSpinBox->setFont(font);
        currLimCSpinBox->setDecimals(3);
        currLimCSpinBox->setMaximum(3250);
        currLimCSpinBox->setSingleStep(0.1);

        gridLayout->addWidget(currLimCSpinBox, 3, 3, 1, 1);

        currLimBSpinBox = new QDoubleSpinBox(gridLayoutWidget);
        currLimBSpinBox->setObjectName(QStringLiteral("currLimBSpinBox"));
        currLimBSpinBox->setFont(font);
        currLimBSpinBox->setDecimals(3);
        currLimBSpinBox->setMaximum(3250);
        currLimBSpinBox->setSingleStep(0.1);

        gridLayout->addWidget(currLimBSpinBox, 2, 3, 1, 1);

        currLimDSpinBox = new QDoubleSpinBox(gridLayoutWidget);
        currLimDSpinBox->setObjectName(QStringLiteral("currLimDSpinBox"));
        currLimDSpinBox->setFont(font);
        currLimDSpinBox->setDecimals(3);
        currLimDSpinBox->setMaximum(3250);
        currLimDSpinBox->setSingleStep(0.1);

        gridLayout->addWidget(currLimDSpinBox, 4, 3, 1, 1);

        label_3 = new QLabel(gridLayoutWidget);
        label_3->setObjectName(QStringLiteral("label_3"));
        label_3->setAlignment(Qt::AlignRight|Qt::AlignTrailing|Qt::AlignVCenter);

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

        label_4 = new QLabel(gridLayoutWidget);
        label_4->setObjectName(QStringLiteral("label_4"));
        label_4->setAlignment(Qt::AlignRight|Qt::AlignTrailing|Qt::AlignVCenter);

        gridLayout->addWidget(label_4, 0, 2, 1, 1);

        lcdNumberAV = new QLabel(gridLayoutWidget);
        lcdNumberAV->setObjectName(QStringLiteral("lcdNumberAV"));
        QPalette palette;
        QBrush brush(QColor(0, 0, 255, 255));
        brush.setStyle(Qt::SolidPattern);
        palette.setBrush(QPalette::Active, QPalette::WindowText, brush);
        QBrush brush1(QColor(255, 255, 255, 255));
        brush1.setStyle(Qt::SolidPattern);
        palette.setBrush(QPalette::Active, QPalette::Light, brush1);
        QBrush brush2(QColor(0, 0, 0, 255));
        brush2.setStyle(Qt::SolidPattern);
        palette.setBrush(QPalette::Active, QPalette::Base, brush2);
        palette.setBrush(QPalette::Inactive, QPalette::WindowText, brush);
        palette.setBrush(QPalette::Inactive, QPalette::Light, brush1);
        palette.setBrush(QPalette::Inactive, QPalette::Base, brush2);
        QBrush brush3(QColor(120, 120, 120, 255));
        brush3.setStyle(Qt::SolidPattern);
        palette.setBrush(QPalette::Disabled, QPalette::WindowText, brush3);
        palette.setBrush(QPalette::Disabled, QPalette::Light, brush1);
        QBrush brush4(QColor(240, 240, 240, 255));
        brush4.setStyle(Qt::SolidPattern);
        palette.setBrush(QPalette::Disabled, QPalette::Base, brush4);
        lcdNumberAV->setPalette(palette);
        lcdNumberAV->setFont(font);
        lcdNumberAV->setAlignment(Qt::AlignRight|Qt::AlignTrailing|Qt::AlignVCenter);

        gridLayout->addWidget(lcdNumberAV, 1, 1, 1, 1);

        lcdNumberBV = new QLabel(gridLayoutWidget);
        lcdNumberBV->setObjectName(QStringLiteral("lcdNumberBV"));
        QPalette palette1;
        palette1.setBrush(QPalette::Active, QPalette::WindowText, brush);
        palette1.setBrush(QPalette::Active, QPalette::Light, brush1);
        palette1.setBrush(QPalette::Active, QPalette::Base, brush2);
        palette1.setBrush(QPalette::Inactive, QPalette::WindowText, brush);
        palette1.setBrush(QPalette::Inactive, QPalette::Light, brush1);
        palette1.setBrush(QPalette::Inactive, QPalette::Base, brush2);
        palette1.setBrush(QPalette::Disabled, QPalette::WindowText, brush3);
        palette1.setBrush(QPalette::Disabled, QPalette::Light, brush1);
        palette1.setBrush(QPalette::Disabled, QPalette::Base, brush4);
        lcdNumberBV->setPalette(palette1);
        lcdNumberBV->setFont(font);
        lcdNumberBV->setAlignment(Qt::AlignRight|Qt::AlignTrailing|Qt::AlignVCenter);

        gridLayout->addWidget(lcdNumberBV, 2, 1, 1, 1);

        lcdNumberCV = new QLabel(gridLayoutWidget);
        lcdNumberCV->setObjectName(QStringLiteral("lcdNumberCV"));
        QPalette palette2;
        palette2.setBrush(QPalette::Active, QPalette::WindowText, brush);
        palette2.setBrush(QPalette::Active, QPalette::Light, brush1);
        palette2.setBrush(QPalette::Active, QPalette::Base, brush2);
        palette2.setBrush(QPalette::Inactive, QPalette::WindowText, brush);
        palette2.setBrush(QPalette::Inactive, QPalette::Light, brush1);
        palette2.setBrush(QPalette::Inactive, QPalette::Base, brush2);
        palette2.setBrush(QPalette::Disabled, QPalette::WindowText, brush3);
        palette2.setBrush(QPalette::Disabled, QPalette::Light, brush1);
        palette2.setBrush(QPalette::Disabled, QPalette::Base, brush4);
        lcdNumberCV->setPalette(palette2);
        lcdNumberCV->setFont(font);
        lcdNumberCV->setAlignment(Qt::AlignRight|Qt::AlignTrailing|Qt::AlignVCenter);

        gridLayout->addWidget(lcdNumberCV, 3, 1, 1, 1);

        lcdNumberDV = new QLabel(gridLayoutWidget);
        lcdNumberDV->setObjectName(QStringLiteral("lcdNumberDV"));
        QPalette palette3;
        palette3.setBrush(QPalette::Active, QPalette::WindowText, brush);
        palette3.setBrush(QPalette::Active, QPalette::Light, brush1);
        palette3.setBrush(QPalette::Active, QPalette::Base, brush2);
        palette3.setBrush(QPalette::Inactive, QPalette::WindowText, brush);
        palette3.setBrush(QPalette::Inactive, QPalette::Light, brush1);
        palette3.setBrush(QPalette::Inactive, QPalette::Base, brush2);
        palette3.setBrush(QPalette::Disabled, QPalette::WindowText, brush3);
        palette3.setBrush(QPalette::Disabled, QPalette::Light, brush1);
        palette3.setBrush(QPalette::Disabled, QPalette::Base, brush4);
        lcdNumberDV->setPalette(palette3);
        lcdNumberDV->setFont(font);
        lcdNumberDV->setAlignment(Qt::AlignRight|Qt::AlignTrailing|Qt::AlignVCenter);

        gridLayout->addWidget(lcdNumberDV, 4, 1, 1, 1);

        lcdNumberAC = new QLabel(gridLayoutWidget);
        lcdNumberAC->setObjectName(QStringLiteral("lcdNumberAC"));
        QPalette palette4;
        palette4.setBrush(QPalette::Active, QPalette::WindowText, brush);
        palette4.setBrush(QPalette::Active, QPalette::Light, brush1);
        palette4.setBrush(QPalette::Active, QPalette::Base, brush2);
        palette4.setBrush(QPalette::Inactive, QPalette::WindowText, brush);
        palette4.setBrush(QPalette::Inactive, QPalette::Light, brush1);
        palette4.setBrush(QPalette::Inactive, QPalette::Base, brush2);
        palette4.setBrush(QPalette::Disabled, QPalette::WindowText, brush3);
        palette4.setBrush(QPalette::Disabled, QPalette::Light, brush1);
        palette4.setBrush(QPalette::Disabled, QPalette::Base, brush4);
        lcdNumberAC->setPalette(palette4);
        lcdNumberAC->setFont(font);
        lcdNumberAC->setAlignment(Qt::AlignRight|Qt::AlignTrailing|Qt::AlignVCenter);

        gridLayout->addWidget(lcdNumberAC, 1, 2, 1, 1);

        lcdNumberBC = new QLabel(gridLayoutWidget);
        lcdNumberBC->setObjectName(QStringLiteral("lcdNumberBC"));
        QPalette palette5;
        palette5.setBrush(QPalette::Active, QPalette::WindowText, brush);
        palette5.setBrush(QPalette::Active, QPalette::Light, brush1);
        palette5.setBrush(QPalette::Active, QPalette::Base, brush2);
        palette5.setBrush(QPalette::Inactive, QPalette::WindowText, brush);
        palette5.setBrush(QPalette::Inactive, QPalette::Light, brush1);
        palette5.setBrush(QPalette::Inactive, QPalette::Base, brush2);
        palette5.setBrush(QPalette::Disabled, QPalette::WindowText, brush3);
        palette5.setBrush(QPalette::Disabled, QPalette::Light, brush1);
        palette5.setBrush(QPalette::Disabled, QPalette::Base, brush4);
        lcdNumberBC->setPalette(palette5);
        lcdNumberBC->setFont(font);
        lcdNumberBC->setAlignment(Qt::AlignRight|Qt::AlignTrailing|Qt::AlignVCenter);

        gridLayout->addWidget(lcdNumberBC, 2, 2, 1, 1);

        lcdNumberCC = new QLabel(gridLayoutWidget);
        lcdNumberCC->setObjectName(QStringLiteral("lcdNumberCC"));
        QPalette palette6;
        palette6.setBrush(QPalette::Active, QPalette::WindowText, brush);
        palette6.setBrush(QPalette::Active, QPalette::Light, brush1);
        palette6.setBrush(QPalette::Active, QPalette::Base, brush2);
        palette6.setBrush(QPalette::Inactive, QPalette::WindowText, brush);
        palette6.setBrush(QPalette::Inactive, QPalette::Light, brush1);
        palette6.setBrush(QPalette::Inactive, QPalette::Base, brush2);
        palette6.setBrush(QPalette::Disabled, QPalette::WindowText, brush3);
        palette6.setBrush(QPalette::Disabled, QPalette::Light, brush1);
        palette6.setBrush(QPalette::Disabled, QPalette::Base, brush4);
        lcdNumberCC->setPalette(palette6);
        lcdNumberCC->setFont(font);
        lcdNumberCC->setAlignment(Qt::AlignRight|Qt::AlignTrailing|Qt::AlignVCenter);

        gridLayout->addWidget(lcdNumberCC, 3, 2, 1, 1);

        lcdNumberDC = new QLabel(gridLayoutWidget);
        lcdNumberDC->setObjectName(QStringLiteral("lcdNumberDC"));
        QPalette palette7;
        palette7.setBrush(QPalette::Active, QPalette::WindowText, brush);
        palette7.setBrush(QPalette::Active, QPalette::Light, brush1);
        palette7.setBrush(QPalette::Active, QPalette::Base, brush2);
        palette7.setBrush(QPalette::Inactive, QPalette::WindowText, brush);
        palette7.setBrush(QPalette::Inactive, QPalette::Light, brush1);
        palette7.setBrush(QPalette::Inactive, QPalette::Base, brush2);
        palette7.setBrush(QPalette::Disabled, QPalette::WindowText, brush3);
        palette7.setBrush(QPalette::Disabled, QPalette::Light, brush1);
        palette7.setBrush(QPalette::Disabled, QPalette::Base, brush4);
        lcdNumberDC->setPalette(palette7);
        lcdNumberDC->setFont(font);
        lcdNumberDC->setAlignment(Qt::AlignRight|Qt::AlignTrailing|Qt::AlignVCenter);

        gridLayout->addWidget(lcdNumberDC, 4, 2, 1, 1);

        checkBoxEnD = new QCheckBox(gridLayoutWidget);
        checkBoxEnD->setObjectName(QStringLiteral("checkBoxEnD"));
        checkBoxEnD->setLayoutDirection(Qt::LeftToRight);

        gridLayout->addWidget(checkBoxEnD, 4, 0, 1, 1);

        label_5 = new QLabel(gridLayoutWidget);
        label_5->setObjectName(QStringLiteral("label_5"));

        gridLayout->addWidget(label_5, 0, 3, 1, 1);

        currLimASpinBox = new QDoubleSpinBox(gridLayoutWidget);
        currLimASpinBox->setObjectName(QStringLiteral("currLimASpinBox"));
        currLimASpinBox->setMaximumSize(QSize(16777215, 16777215));
        currLimASpinBox->setFont(font);
        currLimASpinBox->setDecimals(3);
        currLimASpinBox->setMaximum(3250);
        currLimASpinBox->setSingleStep(0.1);

        gridLayout->addWidget(currLimASpinBox, 1, 3, 1, 1);

        rstPwrBtn = new QPushButton(pwrTab);
        rstPwrBtn->setObjectName(QStringLiteral("rstPwrBtn"));
        rstPwrBtn->setGeometry(QRect(10, 170, 41, 31));
        tabWidget->addTab(pwrTab, QString());
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

        tabWidget->setCurrentIndex(1);


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
        tabWidget->setTabText(tabWidget->indexOf(sysTab), QApplication::translate("MainForm", "Test", 0));
        measureBtn->setText(QApplication::translate("MainForm", "Measure", 0));
        label_3->setText(QApplication::translate("MainForm", "Voltage [V]", 0));
        checkBoxEnC->setText(QApplication::translate("MainForm", "C", 0));
        checkBoxEnB->setText(QApplication::translate("MainForm", "B", 0));
        label_2->setText(QApplication::translate("MainForm", "Enable", 0));
        checkBoxEnA->setText(QApplication::translate("MainForm", "A", 0));
        label_4->setText(QApplication::translate("MainForm", "Current [A]", 0));
        lcdNumberAV->setText(QApplication::translate("MainForm", "0.000", 0));
        lcdNumberBV->setText(QApplication::translate("MainForm", "0.000", 0));
        lcdNumberCV->setText(QApplication::translate("MainForm", "0.000", 0));
        lcdNumberDV->setText(QApplication::translate("MainForm", "0.000", 0));
        lcdNumberAC->setText(QApplication::translate("MainForm", "0.000", 0));
        lcdNumberBC->setText(QApplication::translate("MainForm", "0.000", 0));
        lcdNumberCC->setText(QApplication::translate("MainForm", "0.000", 0));
        lcdNumberDC->setText(QApplication::translate("MainForm", "0.000", 0));
        checkBoxEnD->setText(QApplication::translate("MainForm", "D", 0));
        label_5->setText(QApplication::translate("MainForm", "Current Limit [A]", 0));
        rstPwrBtn->setText(QApplication::translate("MainForm", "Reset ", 0));
        tabWidget->setTabText(tabWidget->indexOf(pwrTab), QApplication::translate("MainForm", "Power Channels", 0));
        menuMenu->setTitle(QApplication::translate("MainForm", "Menu", 0));
    } // retranslateUi

};

namespace Ui {
    class MainForm: public Ui_MainForm {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_MAINFORM_H
