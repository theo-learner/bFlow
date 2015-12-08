#include "mainwindow.h"
#include "ui_mainwindow.h"

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    std::string xmlDB= "db/data6s.xml";
    bool allFlag = false;
    bool partialFlag = false;
    std::string kFlag = "KFR";


    //Need to pass in current line number
    //int lineNumber= lineArg.getValue();

    SearchType sType = ePredict;
    db = new Database(xmlDB, sType);

    //Settings
    db->m_Settings->kgramSimilarity = kFlag;
    db->m_Settings->show_all_result = false;
    db->m_Settings->allsim= allFlag;
    db->m_Settings->partialMatch= partialFlag;

    ui->status_text->setTextColor(Qt::white);
    ui->status_text->append(QTime::currentTime().toString() + ": Setting Complete. Code Away");
    Worker *worker = new Worker;
    worker->moveToThread(&workerThread);
    connect(&workerThread, &QThread::finished, worker, &QObject::deleteLater);
    connect(this, &MainWindow::findSimilarCircuits, worker, &Worker::findSimilarCircuits);
    connect(worker, &Worker::resultReady, this, &MainWindow::handleResults);
    workerThread.start();


    ce = new CodeEditor(this);
    ce->setFixedHeight(761);
    ce->setFixedWidth(711);

    QVBoxLayout *left = new QVBoxLayout;
    left->addWidget(ce);
    this->centralWidget()->setLayout(left);
    connect(ce, SIGNAL(textChanged()), this, SLOT(on_code_change()));




    timer = new QTimer(this);
    connect(timer, SIGNAL(timeout()), this, SLOT(timerUpdate()));

    lock = false;
    num_test = 0;
    num_search = 0;
    num_circuit_check = 0;
    m_Content = "";

    ui->itemTest->setVisible(false);
    ui->itemTest_3->setVisible(false);
    ce->setTabStopWidth(15);
    ce->setEnabled(false);

    ui->itemTest_2->setEnabled(false);
    ui->pushButton->setEnabled(false);
    isSecondDesign = false;

}

MainWindow::~MainWindow()
{
    delete ui;
    delete db;
    workerThread.quit();
    workerThread.wait();
}

void MainWindow::on_itemTest_clicked()
{
    num_test++;
    QProcess process;
    process.start("sh reference/test_sobel.sh");
    process.waitForFinished(-1); // will wait forever until finished

    QString stdout = process.readAllStandardOutput();
    QString stderr = process.readAllStandardError();

    ui->status_text->setTextColor(Qt::cyan);
    ui->status_text->append(QTime::currentTime().toString() + ": " + stdout+stderr);
    ui->status_text->setTextColor(Qt::white);
}



void MainWindow::on_itemTest_3_clicked()
{
    num_test++;
    QProcess process;
    process.start("sh reference/test_max.sh");
    process.waitForFinished(-1); // will wait forever until finished

    QString stdout = process.readAllStandardOutput();
    QString stderr = process.readAllStandardError();

    ui->status_text->setTextColor(Qt::cyan);
    ui->status_text->append(QTime::currentTime().toString() + ": " + stdout+stderr);
    ui->status_text->setTextColor(Qt::white);
}



/*
 * When a reference design has changed
 */
void MainWindow::on_code_change(){
    //Check to see if any change did occur
    QString content = ce->toPlainText();
    if(m_Content == content)
        return;

    m_Content = content;
    QString filename="reference/reference.v";
    QFile file("reference/reference.v" );
    if ( file.open(QIODevice::WriteOnly) )
    {
        QTextStream stream( &file );

        m_Content = ce->toPlainText();
        stream << m_Content << "\n";
        file.close();
    }

    if(timer->isActive())
        timer->setInterval(1500);

    else
        timer->start(1500);
}




void MainWindow::timerUpdate(){
    ui->status_text->append(QTime::currentTime().toString() + ": Snapshot taken");
    timer->stop();
    QString filename="reference/reference.v";
    if(!lock){
        num_search++;
        emit this->findSimilarCircuits(filename, db);
        lock = true;
    }
}



void MainWindow::handleResults(sResult* result){

    if(result == NULL){
        QString content;
        QString filename="data/.pyosys.error";
        QFile file(filename);
        if ( file.open(QIODevice::ReadOnly) )
        {
            QTextStream stream( &file );
            content = stream.readAll();
            file.close();
        }

        if(content.contains("Nothing there to show")){
            ui->status_text->setTextColor(Qt::yellow);
            ui->status_text->append(QTime::currentTime().toString() + ": " + content.mid(content.indexOf(":")+1, -1));
            ui->status_text->setTextColor(Qt::white);
        }
        else{
            ui->status_text->setTextColor(Qt::red);
            ui->status_text->append(QTime::currentTime().toString() + ": " + content);
            ui->status_text->setTextColor(Qt::white);
        }


    }
    else {
        if(tool == 0){
            ui->status_text->setTextColor(Qt::green);
            ui->status_text->append(QTime::currentTime().toString() + ": Compiled Successfully");
            ui->status_text->setTextColor(Qt::white);
        }
        else{
            QProcess process;
            process.start("cp reference/reference.v reference/log/reference_"+QTime::currentTime().toString("hhmmss"));
            process.waitForFinished(-1); // will wait forever until finished

            ui->status_text->setTextColor(Qt::green);
            ui->status_text->append(QTime::currentTime().toString() + ": Search Result Updated");
            ui->status_text->setTextColor(Qt::white);
            ui->listWidget->clear();
            ui->listWidget_2->clear();
            for(unsigned int i = 0; i < result->topMatch.size(); i++){
                QString item = result->topMatch[i].c_str();
                ui->listWidget->addItem(item);
            }
            for(unsigned int i = 0; i < result->topContain.size(); i++){
                QString item = result->topContain[i].c_str();
                ui->listWidget_2->addItem(item);
            }
        }


        delete result;
    }
    lock = false;

}









/*
 * When a circuit is clicked, Show the verilog content
 */

void MainWindow::on_listWidget_itemDoubleClicked(QListWidgetItem *item)
{
    ui->status_text->append(QTime::currentTime().toString() + ": Opening: " + item->text());
    num_circuit_check++;
    QFile file (item->text());
    if(file.open(QIODevice::ReadOnly)){
        QTextStream stream (&file);
        QString str = stream.readAll();

        //QLabel* edit = new QLabel(this);
        QTextEdit* edit = new QTextEdit(this);
        edit->setWindowFlags(Qt::Window);
        edit->setText(str);
        edit->setReadOnly(true);
        edit->setMinimumWidth(700);
        edit->setMinimumHeight(900);
        edit->show();

        //emit openVerilogWindow(str);
    }
    else{
        ui->status_text->append(QTime::currentTime().toString() + ": There was a problem reading in file: " + item->text());
    }
}

void MainWindow::on_listWidget_2_itemDoubleClicked(QListWidgetItem *item)
{
    ui->status_text->append(QTime::currentTime().toString() + ": Opening: " + item->text());
    num_circuit_check++;
    QFile file (item->text());
    if(file.open(QIODevice::ReadOnly)){
        QTextStream stream (&file);
        QString str = stream.readAll();

        //QLabel* edit = new QLabel(this);
        QTextEdit* edit = new QTextEdit(this);
        edit->setWindowFlags(Qt::Window);
        edit->setText(str);
        edit->setReadOnly(true);
        edit->setMinimumWidth(700);
        edit->setMinimumHeight(900);
        edit->show();

        //emit openVerilogWindow(str);
    }
    else{
        ui->status_text->append(QTime::currentTime().toString() + ": There was a problem reading in file: " + item->text());
    }
}


//FINISHEDBUTTON
void MainWindow::on_itemTest_2_clicked()
{
    ui->status_text->append(QTime::currentTime().toString() + ": FINISHED");
    ui->status_text->append( "Number of Searches:               " + QString::number(num_search));
    ui->status_text->append( "Number of Tests Ran:              " + QString::number(num_test));
    ui->status_text->append( "Number of Circuits Viewed :   " + QString::number(num_circuit_check));

    if(!isSecondDesign){
        ce->clear();
        QString filename="reference/reference" + QString::number(design) +"_"+QString::number(tool) + ".v";
        QFile file(filename );
        if ( file.open(QIODevice::WriteOnly) )
        {
            QTextStream stream( &file );

            m_Content = ce->toPlainText();
            stream << m_Content << "\n";
            file.close();
        }

        isSecondDesign = true;
        if(design == 0) {
            design = 1;
            ui->itemTest_3->setVisible(true);
            ui->itemTest->setVisible(false);
            ui->status_text->setTextColor(Qt::magenta);
            ui->status_text->append(QTime::currentTime().toString() + ": Design 1: IMAGE SAMPLING ");
            ui->status_text->setTextColor(Qt::white);
            ce->setEnabled(true);
        }
        else if(design == 1) {
            design = 0;
            ui->itemTest->setVisible(true);
            ui->itemTest_3->setVisible(false);
            ui->status_text->setTextColor(Qt::magenta);
            ui->status_text->append(QTime::currentTime().toString() + ": Design 0: IMAGE EDGE FILTER ");
            ui->status_text->setTextColor(Qt::white);
            ce->setEnabled(true);
        }

        if(tool == 0) {
            tool = 1;
            ui->listWidget->setEnabled(true);
            ui->listWidget_2->setEnabled(true);
            ui->status_text->setTextColor(Qt::magenta);
            ui->status_text->append(QTime::currentTime().toString() + ": Tool: Tool WILL be used");
            ui->status_text->setTextColor(Qt::white);
        }
        else if(tool == 1) {
            tool = 0;
            ui->listWidget->setEnabled(false);
            ui->listWidget_2->setEnabled(false);
            ui->status_text->setTextColor(Qt::magenta);
            ui->status_text->append(QTime::currentTime().toString() + ": Tool: Tool WILL NOT be used");
            ui->status_text->setTextColor(Qt::white);
        }
    }
    else
    {
        ui->status_text->append(QTime::currentTime().toString() + ": Both designs complete.\nExperiment Done!");
        ui->generate_button->setVisible(true);
        ui->itemTest->setVisible(false);
        ui->itemTest_3->setVisible(false);
    }
}


//RESET BUTTON
void MainWindow::on_pushButton_clicked()
{
    ui->listWidget->clear();
    ui->listWidget_2->clear();
    ce->clear();
    ui->status_text->clear();
    lock = false;
    num_test = 0;
    num_search = 0;
    num_circuit_check = 0;
    m_Content = "";
    ui->generate_button->setVisible(true);
    ce->setEnabled(false);
    ui->itemTest->setVisible(false);
    ui->itemTest_3->setVisible(false);
    ui->status_text->setText("Environment was reset\nReady...code away");
}


void MainWindow::on_generate_button_clicked()
{
    qsrand(time(NULL));
    int random = qrand() % 2;
    ui->status_text->setTextColor(Qt::magenta);

    if(random == 0) {
        design = 0;
        ui->itemTest->setVisible(true);
        ui->status_text->append(QTime::currentTime().toString() + ": Design 0: IMAGE EDGE DETECTOR");
    }
    else if(random == 1) {
        design = 1;
        ui->itemTest_3->setVisible(true);
        ui->status_text->append(QTime::currentTime().toString() + ": Design 1: IMAGE SAMPLING ");
    }


    int random2 = qrand() % 2;
    printf("R1: %d  R2: %d\n", random, random2);
    if(random2 == 0) {
        tool = 0;
        ui->listWidget->setEnabled(false);
        ui->listWidget_2->setEnabled(false);
        ui->status_text->append(QTime::currentTime().toString() + ": Tool: Tool WILL NOT be used");
    }
    else if(random2 == 1) {
        tool = 1;
        ui->status_text->append(QTime::currentTime().toString() + ": Tool: Tool WILL be used");
    }

    ui->status_text->setTextColor(Qt::white);
    ce->setEnabled(true);
    ui->generate_button->setVisible(false);
    ui->itemTest_2->setEnabled(true);
    ui->pushButton->setEnabled(true);
    isSecondDesign = false;
}














//CODE FOR LINE NUMBERS
/****************************************************************************
**
** Copyright (C) 2015 The Qt Company Ltd.
** Contact: http://www.qt.io/licensing/
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

#include <QtWidgets>


CodeEditor::CodeEditor(QWidget *parent) : QPlainTextEdit(parent)
{
    lineNumberArea = new LineNumberArea(this);

    connect(this, SIGNAL(blockCountChanged(int)), this, SLOT(updateLineNumberAreaWidth(int)));
    connect(this, SIGNAL(updateRequest(QRect,int)), this, SLOT(updateLineNumberArea(QRect,int)));
    connect(this, SIGNAL(cursorPositionChanged()), this, SLOT(highlightCurrentLine()));

    updateLineNumberAreaWidth(0);
    highlightCurrentLine();
}



int CodeEditor::lineNumberAreaWidth()
{
    int digits = 1;
    int max = qMax(1, blockCount());
    while (max >= 10) {
        max /= 10;
        ++digits;
    }

    int space = 3 + fontMetrics().width(QLatin1Char('9')) * digits;

    return space;
}



void CodeEditor::updateLineNumberAreaWidth(int /* newBlockCount */)
{
    setViewportMargins(lineNumberAreaWidth(), 0, 0, 0);
}



void CodeEditor::updateLineNumberArea(const QRect &rect, int dy)
{
    if (dy)
        lineNumberArea->scroll(0, dy);
    else
        lineNumberArea->update(0, rect.y(), lineNumberArea->width(), rect.height());

    if (rect.contains(viewport()->rect()))
        updateLineNumberAreaWidth(0);
}



void CodeEditor::resizeEvent(QResizeEvent *e)
{
    QPlainTextEdit::resizeEvent(e);

    QRect cr = contentsRect();
    lineNumberArea->setGeometry(QRect(cr.left(), cr.top(), lineNumberAreaWidth(), cr.height()));
}



void CodeEditor::highlightCurrentLine()
{
    QList<QTextEdit::ExtraSelection> extraSelections;

    if (!isReadOnly()) {
        QTextEdit::ExtraSelection selection;

        QColor lineColor = QColor(Qt::yellow).lighter(160);

        selection.format.setBackground(lineColor);
        selection.format.setProperty(QTextFormat::FullWidthSelection, true);
        selection.cursor = textCursor();
        selection.cursor.clearSelection();
        extraSelections.append(selection);
    }

    setExtraSelections(extraSelections);
}



void CodeEditor::lineNumberAreaPaintEvent(QPaintEvent *event)
{
    QPainter painter(lineNumberArea);
    painter.fillRect(event->rect(), Qt::lightGray);


    QTextBlock block = firstVisibleBlock();
    int blockNumber = block.blockNumber();
    int top = (int) blockBoundingGeometry(block).translated(contentOffset()).top();
    int bottom = top + (int) blockBoundingRect(block).height();

    while (block.isValid() && top <= event->rect().bottom()) {
        if (block.isVisible() && bottom >= event->rect().top()) {
            QString number = QString::number(blockNumber + 1);
            painter.setPen(Qt::black);
            painter.drawText(0, top, lineNumberArea->width(), fontMetrics().height(),
                             Qt::AlignRight, number);
        }

        block = block.next();
        top = bottom;
        bottom = top + (int) blockBoundingRect(block).height();
        ++blockNumber;
    }
}





