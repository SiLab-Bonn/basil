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
        tabWidget->setTabText(tabWidget->indexOf(sysTab), QApplication::translate("MainForm", "Test", 0));
        menuMenu->setTitle(QApplication::translate("MainForm", "Menu", 0));
    } // retranslateUi

};

namespace Ui {
    class MainForm: public Ui_MainForm {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_MAINFORM_H
