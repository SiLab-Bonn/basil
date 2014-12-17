/****************************************************************************
** Meta object code from reading C++ file 'MainForm.h'
**
** Created: Sat 20. Apr 12:08:52 2013
**      by: The Qt Meta Object Compiler version 63 (Qt 4.8.4)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "MainForm.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'MainForm.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 63
#error "This file was generated using the moc from 4.8.4. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
static const uint qt_meta_data_MainForm[] = {

 // content:
       6,       // revision
       0,       // classname
       0,    0, // classinfo
      36,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       0,       // signalCount

 // slots: signature, parameters, type, tag, flags
      10,    9,    9,    9, 0x0a,
      27,    9,    9,    9, 0x0a,
      45,    9,    9,    9, 0x0a,
      63,    9,    9,    9, 0x0a,
      74,    9,    9,    9, 0x0a,
      86,    9,    9,    9, 0x0a,
      97,    9,    9,    9, 0x0a,
     109,    9,    9,    9, 0x0a,
     121,    9,    9,    9, 0x0a,
     134,    9,    9,    9, 0x0a,
     147,    9,    9,    9, 0x0a,
     160,    9,    9,    9, 0x0a,
     179,  172,    9,    9, 0x0a,
     196,  172,    9,    9, 0x0a,
     213,  172,    9,    9, 0x0a,
     230,  172,    9,    9, 0x0a,
     251,  247,    9,    9, 0x0a,
     267,  247,    9,    9, 0x0a,
     283,  247,    9,    9, 0x0a,
     299,  247,    9,    9, 0x0a,
     315,  247,    9,    9, 0x0a,
     332,  247,    9,    9, 0x0a,
     349,  247,    9,    9, 0x0a,
     366,  247,    9,    9, 0x0a,
     383,  247,    9,    9, 0x0a,
     400,  247,    9,    9, 0x0a,
     417,  247,    9,    9, 0x0a,
     434,  247,    9,    9, 0x0a,
     451,    9,    9,    9, 0x0a,
     463,    9,    9,    9, 0x0a,
     484,    9,    9,    9, 0x0a,
     499,    9,    9,    9, 0x0a,
     512,    9,    9,    9, 0x0a,
     525,    9,    9,    9, 0x0a,
     540,  533,    9,    9, 0x0a,
     565,  558,    9,    9, 0x0a,

       0        // eod
};

static const char qt_meta_stringdata_MainForm[] = {
    "MainForm\0\0openFileDialog()\0refreshGPIBList()\0"
    "sendReceiveGPIB()\0sendGPIB()\0clearGPIB()\0"
    "setSMUon()\0setSMUoff()\0setSMUval()\0"
    "setSMUCout()\0setSMUVout()\0getSMUMeas()\0"
    "calibrate()\0on_off\0enablePWR0(bool)\0"
    "enablePWR1(bool)\0enablePWR2(bool)\0"
    "enablePWR3(bool)\0val\0setPWR0(double)\0"
    "setPWR1(double)\0setPWR2(double)\0"
    "setPWR3(double)\0setVSRC0(double)\0"
    "setVSRC1(double)\0setVSRC2(double)\0"
    "setVSRC3(double)\0setISRC0(double)\0"
    "setISRC1(double)\0setISRC2(double)\0"
    "setISRC3(double)\0selectSMU()\0"
    "updateMeasurements()\0updateEEPROM()\0"
    "dumpEEPROM()\0setCurrLim()\0setId()\0"
    "yes_no\0enableTimer(bool)\0enable\0"
    "change4WireSense(bool)\0"
};

void MainForm::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        Q_ASSERT(staticMetaObject.cast(_o));
        MainForm *_t = static_cast<MainForm *>(_o);
        switch (_id) {
        case 0: _t->openFileDialog(); break;
        case 1: _t->refreshGPIBList(); break;
        case 2: _t->sendReceiveGPIB(); break;
        case 3: _t->sendGPIB(); break;
        case 4: _t->clearGPIB(); break;
        case 5: _t->setSMUon(); break;
        case 6: _t->setSMUoff(); break;
        case 7: _t->setSMUval(); break;
        case 8: _t->setSMUCout(); break;
        case 9: _t->setSMUVout(); break;
        case 10: _t->getSMUMeas(); break;
        case 11: _t->calibrate(); break;
        case 12: _t->enablePWR0((*reinterpret_cast< bool(*)>(_a[1]))); break;
        case 13: _t->enablePWR1((*reinterpret_cast< bool(*)>(_a[1]))); break;
        case 14: _t->enablePWR2((*reinterpret_cast< bool(*)>(_a[1]))); break;
        case 15: _t->enablePWR3((*reinterpret_cast< bool(*)>(_a[1]))); break;
        case 16: _t->setPWR0((*reinterpret_cast< double(*)>(_a[1]))); break;
        case 17: _t->setPWR1((*reinterpret_cast< double(*)>(_a[1]))); break;
        case 18: _t->setPWR2((*reinterpret_cast< double(*)>(_a[1]))); break;
        case 19: _t->setPWR3((*reinterpret_cast< double(*)>(_a[1]))); break;
        case 20: _t->setVSRC0((*reinterpret_cast< double(*)>(_a[1]))); break;
        case 21: _t->setVSRC1((*reinterpret_cast< double(*)>(_a[1]))); break;
        case 22: _t->setVSRC2((*reinterpret_cast< double(*)>(_a[1]))); break;
        case 23: _t->setVSRC3((*reinterpret_cast< double(*)>(_a[1]))); break;
        case 24: _t->setISRC0((*reinterpret_cast< double(*)>(_a[1]))); break;
        case 25: _t->setISRC1((*reinterpret_cast< double(*)>(_a[1]))); break;
        case 26: _t->setISRC2((*reinterpret_cast< double(*)>(_a[1]))); break;
        case 27: _t->setISRC3((*reinterpret_cast< double(*)>(_a[1]))); break;
        case 28: _t->selectSMU(); break;
        case 29: _t->updateMeasurements(); break;
        case 30: _t->updateEEPROM(); break;
        case 31: _t->dumpEEPROM(); break;
        case 32: _t->setCurrLim(); break;
        case 33: _t->setId(); break;
        case 34: _t->enableTimer((*reinterpret_cast< bool(*)>(_a[1]))); break;
        case 35: _t->change4WireSense((*reinterpret_cast< bool(*)>(_a[1]))); break;
        default: ;
        }
    }
}

const QMetaObjectExtraData MainForm::staticMetaObjectExtraData = {
    0,  qt_static_metacall 
};

const QMetaObject MainForm::staticMetaObject = {
    { &QWidget::staticMetaObject, qt_meta_stringdata_MainForm,
      qt_meta_data_MainForm, &staticMetaObjectExtraData }
};

#ifdef Q_NO_DATA_RELOCATION
const QMetaObject &MainForm::getStaticMetaObject() { return staticMetaObject; }
#endif //Q_NO_DATA_RELOCATION

const QMetaObject *MainForm::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->metaObject : &staticMetaObject;
}

void *MainForm::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_MainForm))
        return static_cast<void*>(const_cast< MainForm*>(this));
    if (!strcmp(_clname, "Ui_MainForm"))
        return static_cast< Ui_MainForm*>(const_cast< MainForm*>(this));
    return QWidget::qt_metacast(_clname);
}

int MainForm::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QWidget::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 36)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 36;
    }
    return _id;
}
QT_END_MOC_NAMESPACE
