import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.StringJoiner ; 
import java.util.Arrays ;
import netP5.*;
import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;
import oscP5.*;
import processing.awt.*;

final Logger L = Logger.getLogger(getClass());

boolean connected = false;
int MY_OSC_PORT = -1;

// 複数ポート監視用
final int MAX_PORTS = 3;
OscP5[] oscServers = new OscP5[MAX_PORTS];
int[] portNumbers = new int[MAX_PORTS];
boolean[] portConnected = new boolean[MAX_PORTS];
String[] portLabels = {"Port 1", "Port 2", "Port 3"};

static int W_WIDTH = 720;
static int W_HEIGHT = 410;

OscP5 oscP5;
JSONObject config;
int bgColor;

JTextField[] portTextFields = new JTextField[MAX_PORTS];
JButton[] connectButtons = new JButton[MAX_PORTS];
JButton clearButton;
JTextArea logTextArea;
JLabel[] portStatusLabels = new JLabel[MAX_PORTS];

ArrayList<String> logText = new ArrayList<String>();

/**
 *
 */
void settings() {
  System.setProperty("logging.dir", dataPath("../log/"));
  PropertyConfigurator.configure(dataPath("log4j.properties"));

  logText.add(0, "[" +getFormattedDate() + "]logging.dir = " + dataPath("../log/"));

  loadConfig();
  size(W_WIDTH, W_HEIGHT);
}
  
/**
 *
 */
void setup() {
  Canvas canvas = (Canvas)surface.getNative();
  JLayeredPane pane = (JLayeredPane)canvas.getParent().getParent();

  GuiListener listener = new GuiListener(this);

  // 複数ポートのUIを作成
  for (int i = 0; i < MAX_PORTS; i++) {
    int yPos = 10 + i * 50;
    
    // ポート番号入力フィールド
    portTextFields[i] = new JTextField();
    portTextFields[i].addKeyListener(listener);
    portTextFields[i].setText(Integer.toString(portNumbers[i]));
    portTextFields[i].setBounds(20, yPos, 100, 25);
    pane.add(portTextFields[i]);

    // ポートラベル
    JLabel portLabel = new JLabel(portLabels[i]);
    portLabel.setBounds(20, yPos + 25, 100, 20);
    pane.add(portLabel);

    // 接続ボタン
    connectButtons[i] = new JButton("Connect");
    connectButtons[i].addActionListener(listener);
    connectButtons[i].setBounds(130, yPos, 80, 25);
    pane.add(connectButtons[i]);

    // ステータスラベル
    portStatusLabels[i] = new JLabel("Disconnected");
    portStatusLabels[i].setBounds(220, yPos, 100, 25);
    portStatusLabels[i].setForeground(Color.RED);
    pane.add(portStatusLabels[i]);
  }

  // clearボタン
  clearButton = new JButton("Clear All");
  clearButton.addActionListener(listener);
  clearButton.setBounds(550, 10, 150, 30);
  pane.add(clearButton);

  // デバッグ表示用エリア
  logTextArea = new JTextArea();
  logTextArea.setLineWrap(true);
  JScrollPane scrollpane = new JScrollPane(
      logTextArea,
      JScrollPane.VERTICAL_SCROLLBAR_ALWAYS,
      JScrollPane.HORIZONTAL_SCROLLBAR_ALWAYS);
  scrollpane.setPreferredSize(new Dimension(450, 300));
  scrollpane.setBounds(
      20, 170, 680, (height - 170) - 20);
  pane.add(scrollpane);

  logTextArea.setText(String.join("\r\n", logText));

  // set background color
  bgColor = canvas.getBackground().getRGB();
  background(bgColor);
}

/**
 *
 */
void draw() {
  background(bgColor);
}

/**
 *
 */
void loadConfig() {
  config = loadJSONObject(dataPath("config.json"));

  // 複数ポートの設定を読み込み
  if (config.hasKey("ports")) {
    JSONArray ports = config.getJSONArray("ports");
    for (int i = 0; i < MAX_PORTS && i < ports.size(); i++) {
      portNumbers[i] = ports.getInt(i);
    }
  } else {
    // デフォルトポート設定
    portNumbers[0] = 8001;
    portNumbers[1] = 8002;
    portNumbers[2] = 8003;
  }
  
  // 後方互換性のため
  MY_OSC_PORT = portNumbers[0];
}

/**
 *
 */
void connect() {
  // 後方互換性のため、最初のポートに接続
  connectPort(0);
}

void connectPort(int portIndex) {
  if (portIndex < 0 || portIndex >= MAX_PORTS) return;
  
  try {
    // 既存の接続があれば切断
    if (oscServers[portIndex] != null) {
      disconnectPort(portIndex);
    }

    // ポート番号を取得
    int portNumber = Integer.parseInt(portTextFields[portIndex].getText());
    portNumbers[portIndex] = portNumber;

    // OSCの接続開始
    OscProperties properties = new OscProperties();
    properties.setDatagramSize(100000);
    properties.setListeningPort(portNumber);
    oscServers[portIndex] = new OscP5(this, properties);
    portConnected[portIndex] = true;
    
    // UI更新
    connectButtons[portIndex].setText("Disconnect");
    portStatusLabels[portIndex].setText("Connected");
    portStatusLabels[portIndex].setForeground(Color.GREEN);
    
    logText.add(0, "[" + getFormattedDate() + "]Port " + (portIndex + 1) + " connected on " + portNumber);
    updateLogDisplay();
    
    // 設定を保存
    saveConfig();
    
  } catch (Exception e) {
    logText.add(0, "[" + getFormattedDate() + "]Port " + (portIndex + 1) + " connection failed: " + e.getMessage());
    updateLogDisplay();
  }
}

/**
 *
 */
void disconnect() {
  // 後方互換性のため、最初のポートを切断
  disconnectPort(0);
}

void disconnectPort(int portIndex) {
  if (portIndex < 0 || portIndex >= MAX_PORTS) return;
  
  if (oscServers[portIndex] != null) {
    oscServers[portIndex].dispose();
    oscServers[portIndex] = null;
    portConnected[portIndex] = false;
    
    // UI更新
    connectButtons[portIndex].setText("Connect");
    portStatusLabels[portIndex].setText("Disconnected");
    portStatusLabels[portIndex].setForeground(Color.RED);
    
    logText.add(0, "[" + getFormattedDate() + "]Port " + (portIndex + 1) + " disconnected");
    updateLogDisplay();
  }
}

void disconnectAll() {
  for (int i = 0; i < MAX_PORTS; i++) {
    disconnectPort(i);
  }
}

/**
 *
 */
void oscEvent(OscMessage _msg) {
  // どのポートからメッセージが来たかを特定
  int sourcePort = -1;
  for (int i = 0; i < MAX_PORTS; i++) {
    if (oscServers[i] != null && portConnected[i]) {
      // ポート番号で特定（簡易実装）
      sourcePort = portNumbers[i];
      break;
    }
  }
  
  String portInfo = sourcePort > 0 ? "[Port " + sourcePort + "] " : "";
  logText.add(0, "[" + getFormattedDate() + "]" + portInfo + parseOscMessageToString(_msg));
  updateLogDisplay();
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
        logText.add("[parseOscMessageToString exception]" + e2);
      }
    }
    txt += ",  ";
  }
  return txt;
}

String getFormattedDate() {
  DateFormat format = new SimpleDateFormat("yyyy/MM/dd hh:mm:ss.SSS");
  String date = format.format(new Date());
  return date;
}

/**
 * ログ表示を更新
 */
void updateLogDisplay() {
  if (logTextArea != null) {
    logTextArea.setText(String.join("\r\n", logText));
    if (logText.size() > 1000) {
      logText.remove(logText.size() - 1);
    }
  }
}

/**
 * 設定を保存
 */
void saveConfig() {
  try {
    JSONArray ports = new JSONArray();
    for (int i = 0; i < MAX_PORTS; i++) {
      ports.setInt(i, portNumbers[i]);
    }
    config.setJSONArray("ports", ports);
    saveJSONObject(config, dataPath("config.json"));
  } catch (Exception e) {
    logText.add(0, "[" + getFormattedDate() + "]Config save error: " + e.getMessage());
  }
}
