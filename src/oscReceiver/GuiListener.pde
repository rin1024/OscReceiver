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
    // 接続ボタンが押された
    if (e.getSource() == bindButton) {
      if (connected == true) {
        disconnect();
        bindButton.setText("Connect");
        logText += "disconnect." + "\r\n";
      }
      else {
        connect();
        bindButton.setText("Disconnect");
        logText += "connect osc port = " + MY_OSC_PORT + ".\r\n";
      }
      logTextArea.setText(logText);
    }
  }
}  
