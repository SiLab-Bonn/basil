#pragma once
#include <qwt_plot.h>
#include <qwt_plot_curve.h>
#include <qwt_text.h>
#include <qwt_compat.h>
#if QT_VERSION >= 0x040000
#include <qprintdialog.h>
#endif
#include <QPrinter.h>
#include <qwt_color_map.h>
#include <qwt_plot_spectrogram.h>
#include <qwt_scale_widget.h>
#include <qwt_scale_draw.h>
#include <qwt_plot_zoomer.h>
#include <qwt_plot_panner.h>
#include <qwt_plot_layout.h>

class SimpleQWTPlot :
	public QwtPlot
{
public:
	SimpleQWTPlot(QwtPlot *parent, double xmin, double xmax, double ymin, double ymax, QString title);
	~SimpleQWTPlot(void);
	void Print();
protected:

};
