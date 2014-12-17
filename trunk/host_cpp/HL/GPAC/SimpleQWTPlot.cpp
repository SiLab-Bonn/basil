#include "SimpleQWTPlot.h"

// helper class for zooming


class MyZoomer: public QwtPlotZoomer
{
public:
    MyZoomer(QwtPlotCanvas *canvas): QwtPlotZoomer(canvas)
    {
        setTrackerMode(ActiveOnly);
    }

    virtual QwtText trackerText(const QwtDoublePoint &pos) const
    {
        QColor bg(Qt::white);
        bg.setAlpha(200);
				QwtText text = QwtPlotZoomer::trackerText(pos.toPoint());
        text.setBackgroundBrush( QBrush( bg ));
        return text;
    }
};

SimpleQWTPlot::SimpleQWTPlot(QwtPlot *parentPlot,  double xmin, double xmax, double ymin, double ymax, QString title):
                             QwtPlot(QwtText(title), parentPlot->parentWidget())
{
	// some hack to copy parameteres of the base class instance as a graphical template for the derived instance
	this->setGeometry(parentPlot->geometry()); // copy geometry from QWTPlot widget as placed with Qt designer
	parentPlot->hide();  // hide template plot
	this->show(); // show our plot

	setAxisScale(QwtPlot::yLeft, ymin, ymax);
	setAxisScale(QwtPlot::xBottom, xmin, xmax);

	plotLayout()->setAlignCanvasToScales(true);
    replot();  

	QwtPlotZoomer* zoomer = new MyZoomer(canvas());
	zoomer->initMousePattern(2);
    zoomer->setMousePattern(QwtEventPattern::MouseSelect1, Qt::LeftButton, Qt::NoButton); // zoom rectangle
    zoomer->setMousePattern(QwtEventPattern::MouseSelect2, Qt::LeftButton, Qt::ControlModifier); // zoom all ???
    zoomer->setMousePattern(QwtEventPattern::MouseSelect3, Qt::LeftButton, Qt::ShiftModifier); // zoom out


	QwtPlotPanner *panner = new QwtPlotPanner(canvas());
    panner->setAxisEnabled(QwtPlot::yRight, false);
	panner->setMouseButton(Qt::RightButton, Qt::NoButton);

    // Avoid jumping when labels with more/less digits
    // appear/disappear when scrolling vertically

    const QFontMetrics fm(axisWidget(QwtPlot::yLeft)->font());
    QwtScaleDraw *sd = axisScaleDraw(QwtPlot::yLeft);
    sd->setMinimumExtent( fm.width("100.00") );

    const QColor c(Qt::darkBlue);
    zoomer->setRubberBandPen(c);
    zoomer->setTrackerPen(c);
}

SimpleQWTPlot::~SimpleQWTPlot(void)
{
}

void SimpleQWTPlot::Print(void)
{
  QPrinter printer;
  QwtText plotName = title();
  printer.setOrientation(QPrinter::Landscape);
//  printer.setOutputFileName(plotName.text() + ".pdf");
  QPrintDialog dialog(&printer, this);
  if ( dialog.exec() )
  {
      //print(printer); ???
		;
  }
}

