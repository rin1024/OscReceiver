class GuiListener implements ItemListener, ChangeListener, ActionListener, KeyListener {
  PApplet pa;

  GuiListener(PApplet _pa) {
    pa = _pa;
  }

  void itemStateChanged(ItemEvent e) {
  }

  void stateChanged(ChangeEvent e) {
  }

  /**
   * テキストボックス内でのエンターキー押下によるコマンド送信
   */
  void keyPressed(java.awt.event.KeyEvent e) {
    if (e.getKeyCode() == java.awt.event.KeyEvent.VK_ENTER) {
      //if (e.getSource() == serialMonitors[i].sendText) {
      //}
    }
  }

  void keyReleased(java.awt.event.KeyEvent e) {
    if (e.getKeyCode() == java.awt.event.KeyEvent.VK_ENTER) {
    }
  }

  void keyTyped(java.awt.event.KeyEvent e) {
    if (e.getKeyCode() == java.awt.event.KeyEvent.VK_ENTER) {
    }
  }

  void actionPerformed(ActionEvent e) {
    // clearボタンが押された
    if (e.getSource() == clearButton) {
      logText.clear();
      for (int i = 0; i < 3; i++) { // MAX_PORTS = 3
        if (portLogTexts[i] != null) {
          portLogTexts[i].clear();
          updatePortLogDisplay(i);
        }
      }
    }
    // ポート追加ボタンが押された
    else if (e.getSource() == addPortButton) {
      addPort();
    }
    // ポート削除ボタンが押された
    else if (e.getSource() == removePortButton) {
      removePort();
    }
    // 接続ボタンが押された（複数ポート対応）
    else {
      for (int i = 0; i < 3; i++) { // MAX_PORTS = 3
        if (e.getSource() == connectButtons[i]) {
          if (portConnected[i]) {
            disconnectPort(i);
          } else {
            try {
              int portNumber = Integer.parseInt(portTextFields[i].getText());
              
              // ポート番号の妥当性をチェック
              if (portNumber < 1024 || portNumber > 65535) {
                logText.add(0, "[" + getFormattedDate() + "]Invalid port number. Please use a port between 1024 and 65535.");
                updateLogDisplay();
                return;
              }

              connectPort(i);
              
            } catch (NumberFormatException ex) {
              logText.add(0, "[" + getFormattedDate() + "]Invalid port number format. Please enter a valid number.");
              updateLogDisplay();
            }
          }
          break;
        }
      }
    }
  }
}  
