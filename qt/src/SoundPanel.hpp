#pragma once
#include "ui_SoundPanel.h"
#include "EmuApplication.hpp"
#include <QMenu>

class SoundPanel :
    public Ui::SoundPanel,
    public QWidget
{
  public:
    SoundPanel(EmuApplication *app);
    ~SoundPanel();
    EmuApplication *app;
    void showEvent(QShowEvent *event) override;
    void updateInputRate();

    std::vector<std::string> driver_list;
};