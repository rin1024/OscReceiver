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
      logText = "";
      logTextArea.setText(logText);
    }
    // 接続ボタンが押された
    else if (e.getSource() == bindButton) {
      if (connected == true) {
        disconnect();
        bindButton.setText("Connect");
        
        logText = "[" +(new Date().toString()) + "]disconnect.\r\n" + logText;
      }
      else {
        MY_OSC_PORT = Integer.parseInt(myPort.getText());

        connect();
        bindButton.setText("Disconnect");

        logText = "[" +(new Date().toString()) + "]connect osc port = " + MY_OSC_PORT + ".\r\n" + logText;
      }
      logTextArea.setText(logText);
    }
  }
}  
