import oscP5.*;
import netP5.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.util.Date;
import java.util.StringJoiner ; 
import java.util.Arrays ;

boolean connected = false;
int MY_OSC_PORT = -1;

static int W_WIDTH = 720;
static int W_HEIGHT = 410;

OscP5 oscP5;
JSONObject config;

JTextField myPort;
JButton bindButton;
JButton clearButton;
JTextArea logTextArea;

ArrayList<String> logText;

/**
 *
 */
void setup() {
  surface.setVisible(false);

  loadConfig();

  GuiListener listener = new GuiListener(this);

  JPanel panel = new JPanel();
  panel.setLayout(null);

  // 自分のポート
  myPort = new JTextField();
  myPort.addKeyListener(listener);
  myPort.setText(Integer.toString(MY_OSC_PORT));
  myPort.setBounds(
    20, 10, 150, 30);
  panel.add(myPort);

  {
    JLabel l = new JLabel("My OSC Port");
    l.setBounds(
        20 + 2, 10 + 25, 150, 30);
    panel.add(l);
  }

  // 接続ボタン
  bindButton = new JButton("Connect");
  bindButton.addActionListener(listener);
  bindButton.setBounds(
    180, 10, 150, 30);
  panel.add(bindButton);

  // clearボタン
  clearButton = new JButton("Clear");
  clearButton.addActionListener(listener);
  clearButton.setBounds(
    550, 10, 150, 30);
  panel.add(clearButton);

  // デバッグ表示用エリア
  logTextArea = new JTextArea();
  logTextArea.setLineWrap(true);
  JScrollPane scrollpane = new JScrollPane(
      logTextArea,
      JScrollPane.VERTICAL_SCROLLBAR_ALWAYS,
      JScrollPane.HORIZONTAL_SCROLLBAR_ALWAYS);
  scrollpane.setPreferredSize(new Dimension(450, 400));
  scrollpane.setBounds(
      20, 70, 680, 300);
  panel.add(scrollpane);

  // 表示用フレーム
  JFrame f = new JFrame("Osc Receiver");
  f.add(panel);
  f.setSize(W_WIDTH, W_HEIGHT);
  f.setVisible(true);

  logText = new ArrayList<String>();
}

/**
 *
 */
void draw() {
}

/**
 *
 */
void loadConfig() {
  config = loadJSONObject(dataPath("config.json"));

  // 自分のポートを指定
  MY_OSC_PORT = config.getInt("myOscPort");
}

/**
 *
 */
void connect() {
  if (oscP5 != null) {
    oscP5.dispose();
    oscP5 = null;
  }

  // OSCの接続開始
  OscProperties properties = new OscProperties();
  properties.setDatagramSize(100000); //1536
  properties.setListeningPort(MY_OSC_PORT);
  oscP5 = new OscP5(this, properties);
  connected = true;
}

/**
 *
 */
void disconnect() {
  if (oscP5 != null) {
    oscP5.dispose();
    oscP5 = null;
  }
  connected = false;
}

/**
 *
 */
void oscEvent(OscMessage _msg) {
  logText.add(0, "[" +(new Date().toString()) + "]" + parseOscMessageToString(_msg));
  logTextArea.setText(String.join("\r\n", logText));
  if (logText.size() > 1000) {
    logText.remove(logText.size() - 1);
  }
}

/**
 * OSCで送受信[した|してる]パラメータを文字列にパース
 */
String parseOscMessageToString(OscMessage _msg) {
  String _addr = _msg.addrPattern();
  Object[] _list = _msg.arguments();

  String txt = _addr + ": ";
  for (int i=0;i<_list.length;i++) {
    try {
      txt += "[" + Integer.valueOf((String) _list[i]) + "]";
    }
    catch (Exception e) {
      try {
        txt += "[" + _list[i].toString() + "]";
      }
      catch (Exception e2) {
        println(e2);
      }
    }
    txt += ",  ";
  }
  return txt;
}
