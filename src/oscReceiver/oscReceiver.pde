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
import processing.awt.PSurfaceAWT.SmoothCanvas;
import processing.awt.*;

final Logger L = Logger.getLogger(getClass());

boolean connected = false;
int MY_OSC_PORT = -1;

// 複数ポート監視用
final int MAX_PORTS = 3;
OscP5[] oscServers = new OscP5[MAX_PORTS];
int[] portNumbers = new int[MAX_PORTS];
boolean[] portConnected = new boolean[MAX_PORTS];
String[] portLabelTexts = {"Port 1", "Port 2", "Port 3"};
int currentPortCount = 1; // 現在表示されているポート数

OscP5 oscP5;
OscReceiverConfig config;
int bgColor;

JTextField[] portTextFields = new JTextField[MAX_PORTS];
JButton[] connectButtons = new JButton[MAX_PORTS];
JButton clearButton;
JButton addPortButton;
JButton removePortButton;
JTextArea[] logTextAreas = new JTextArea[MAX_PORTS];
JLabel[] portStatusLabels = new JLabel[MAX_PORTS];
JScrollPane[] portScrollPanes = new JScrollPane[MAX_PORTS];
JLabel[] portLabels = new JLabel[MAX_PORTS];

ArrayList<String> logText = new ArrayList<String>();
ArrayList<String>[] portLogTexts = new ArrayList[MAX_PORTS];

/**
 *
 */
void settings() {
  // 設定管理の初期化
  config = new OscReceiverConfig(this);
  config.setupConfig();

  logText.add(0, "[" +getFormattedDate() + "]logging.dir = " + config.getLogDirectory());

  loadConfig();

  // ウィンドウサイズと位置を設定
  size(config.getWindowWidth(), config.getWindowHeight());
}

/**
 *
 */
void setup() {
  Canvas canvas = (Canvas)surface.getNative();
  JLayeredPane pane = (JLayeredPane)canvas.getParent().getParent();

  // ウィンドウ位置を設定
  surface.setLocation(config.getWindowX(), config.getWindowY());

  GuiListener listener = new GuiListener(this);

  // ポート管理ボタン
  addPortButton = new JButton("+");
  addPortButton.addActionListener(listener);
  addPortButton.setBounds(20, 10, 30, 25);
  pane.add(addPortButton);

  removePortButton = new JButton("-");
  removePortButton.addActionListener(listener);
  removePortButton.setBounds(55, 10, 30, 25);
  pane.add(removePortButton);

  // ポート数表示ラベル
  JLabel portCountLabel = new JLabel("Ports: 1");
  portCountLabel.setBounds(90, 10, 80, 25);
  pane.add(portCountLabel);

  // 初期ポート表示
  updatePortDisplay();

  // clearボタン
  clearButton = new JButton("Clear All");
  clearButton.addActionListener(listener);
  clearButton.setBounds(650, 10, 120, 30);
  pane.add(clearButton);

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
  // 設定からポート情報を取得
  int[] configPorts = config.getPortNumbers();
  System.arraycopy(configPorts, 0, portNumbers, 0, MAX_PORTS);
  currentPortCount = config.getCurrentPortCount();

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
    portLogTexts[portIndex].add(0, "[" + getFormattedDate() + "]Connected on port " + portNumber);
    updatePortLogDisplay(portIndex);

    // 設定を保存
    saveConfig();
  }
  catch (Exception e) {
    logText.add(0, "[" + getFormattedDate() + "]Port " + (portIndex + 1) + " connection failed: " + e.getMessage());
    portLogTexts[portIndex].add(0, "[" + getFormattedDate() + "]Connection failed: " + e.getMessage());
    updatePortLogDisplay(portIndex);
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
    portLogTexts[portIndex].add(0, "[" + getFormattedDate() + "]Disconnected");
    updatePortLogDisplay(portIndex);
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
  int sourcePortIndex = -1;
  for (int i = 0; i < MAX_PORTS; i++) {
    if (oscServers[i] != null && portConnected[i]) {
      sourcePortIndex = i;
      break;
    }
  }

  if (sourcePortIndex >= 0) {
    String logEntry = "[" + getFormattedDate() + "]" + parseOscMessageToString(_msg);

    // 該当ポートのログに追加
    portLogTexts[sourcePortIndex].add(0, logEntry);

    // ログサイズを制限
    if (portLogTexts[sourcePortIndex].size() > 100) {
      portLogTexts[sourcePortIndex].remove(portLogTexts[sourcePortIndex].size() - 1);
    }

    // 該当ポートのテキストエリアを更新
    updatePortLogDisplay(sourcePortIndex);
  }
}

/**
 * OSCで送受信[した|してる]パラメータを文字列にパース
 */
String parseOscMessageToString(OscMessage _msg) {
  String _addr = _msg.addrPattern();
  Object[] _list = _msg.arguments();

  String txt = _addr + ": ";
  for (int i=0; i<_list.length; i++) {
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
 * ログ表示を更新（後方互換性のため残している）
 */
void updateLogDisplay() {
  // このメソッドは後方互換性のため残しているが、実際は使用されない
  // 各ポートのログは updatePortLogDisplay() で個別に更新される
}

/**
 * 指定されたポートのログ表示を更新
 */
void updatePortLogDisplay(int portIndex) {
  if (portIndex >= 0 && portIndex < MAX_PORTS && logTextAreas[portIndex] != null) {
    logTextAreas[portIndex].setText(String.join("\r\n", portLogTexts[portIndex]));
  }
}

/**
 * ポート表示を更新
 */
void updatePortDisplay() {
  Canvas canvas = (Canvas)surface.getNative();
  JLayeredPane pane = (JLayeredPane)canvas.getParent().getParent();

  // 既存のポートUIを削除
  for (int i = 0; i < MAX_PORTS; i++) {
    if (portLabels[i] != null) {
      pane.remove(portLabels[i]);
      portLabels[i] = null;
    }
    if (portTextFields[i] != null) {
      pane.remove(portTextFields[i]);
      portTextFields[i] = null;
    }
    if (connectButtons[i] != null) {
      pane.remove(connectButtons[i]);
      connectButtons[i] = null;
    }
    if (portStatusLabels[i] != null) {
      pane.remove(portStatusLabels[i]);
      portStatusLabels[i] = null;
    }
    if (portScrollPanes[i] != null) {
      pane.remove(portScrollPanes[i]);
      portScrollPanes[i] = null;
      logTextAreas[i] = null;
    }
  }

  // 現在のポート数分だけUIを作成
  for (int i = 0; i < currentPortCount; i++) {
    int yPos = 40; // ボタンの下に配置

    // ポート数に応じて幅と位置を計算
    int textAreaWidth, xPos;
    if (currentPortCount == 1) {
      // 1ポートの場合は画面幅いっぱい
      textAreaWidth = width - 40; // 左右のマージン20pxずつ
      xPos = 20;
    } else if (currentPortCount == 2) {
      // 2ポートの場合は2分割
      textAreaWidth = (width - 60) / 2; // 左右のマージン20px + 中央の間隔20px
      xPos = 20 + i * (textAreaWidth + 20);
    } else {
      // 3ポートの場合は3分割
      textAreaWidth = (width - 80) / 3; // 左右のマージン20px + 間隔20pxずつ
      xPos = 20 + i * (textAreaWidth + 20);
    }

    // ポートラベル
    portLabels[i] = new JLabel(portLabelTexts[i]);
    portLabels[i].setBounds(xPos, yPos, 100, 20);
    pane.add(portLabels[i]);

    // ポート番号入力フィールド
    portTextFields[i] = new JTextField();
    portTextFields[i].addKeyListener(new GuiListener(this));
    portTextFields[i].setText(Integer.toString(portNumbers[i]));
    portTextFields[i].setBounds(xPos, yPos + 25, 80, 25);
    pane.add(portTextFields[i]);

    // 接続ボタン
    connectButtons[i] = new JButton("Connect");
    connectButtons[i].addActionListener(new GuiListener(this));
    connectButtons[i].setBounds(xPos + 85, yPos + 25, 80, 25);
    pane.add(connectButtons[i]);

    // ステータスラベル
    portStatusLabels[i] = new JLabel("Disconnected");
    portStatusLabels[i].setBounds(xPos, yPos + 55, 100, 20);
    portStatusLabels[i].setForeground(Color.RED);
    pane.add(portStatusLabels[i]);

    // ポート専用のログテキストエリア
    if (portLogTexts[i] == null) {
      portLogTexts[i] = new ArrayList<String>();
    }
    logTextAreas[i] = new JTextArea();
    logTextAreas[i].setLineWrap(true);
    portScrollPanes[i] = new JScrollPane(
      logTextAreas[i],
      JScrollPane.VERTICAL_SCROLLBAR_ALWAYS,
      JScrollPane.HORIZONTAL_SCROLLBAR_ALWAYS);
    portScrollPanes[i].setPreferredSize(new Dimension(textAreaWidth, 300));
    portScrollPanes[i].setBounds(xPos, yPos + 80, textAreaWidth, 300);
    pane.add(portScrollPanes[i]);
  }

  // ボタンの有効/無効を更新
  addPortButton.setEnabled(currentPortCount < MAX_PORTS);
  removePortButton.setEnabled(currentPortCount > 1);

  // ポート数表示を更新
  JLabel portCountLabel = (JLabel)pane.getComponent(2); // ポート数ラベルのインデックス
  if (portCountLabel != null) {
    portCountLabel.setText("Ports: " + currentPortCount);
  }

  pane.revalidate();
  pane.repaint();
}

/**
 * ポートを追加
 */
void addPort() {
  if (currentPortCount < MAX_PORTS) {
    currentPortCount++;
    updatePortDisplay();
  }
}

/**
 * ポートを削除
 */
void removePort() {
  if (currentPortCount > 1) {
    // 最後のポートが接続中なら切断
    int lastIndex = currentPortCount - 1;
    if (portConnected[lastIndex]) {
      disconnectPort(lastIndex);
    }
    currentPortCount--;
    updatePortDisplay();
  }
}

/**
 * 設定を保存
 */
void saveConfig() {
  try {
    config.savePortConfig(portNumbers, currentPortCount);
  }
  catch (Exception e) {
    logText.add(0, "[" + getFormattedDate() + "]Config save error: " + e.getMessage());
  }
}

/**
 * アプリケーション終了時の処理
 */
void exit() {
  try {
    JFrame frame = (JFrame) ((SmoothCanvas) getSurface().getNative()).getFrame();

    int currentWidth = width;
    int currentHeight = height;
    int currentX = frame.getX(); // 前回の位置を保持
    int currentY = frame.getY(); // 前回の位置を保持

    config.saveWindowPosition(currentX, currentY, currentWidth, currentHeight);
    L.info("ウィンドウ位置を保存しました: [" + currentX + "," + currentY + "]");
  }
  catch (Exception e) {
    L.warn("ウィンドウ位置の保存に失敗しました: " + e.getMessage());
  }

  // すべてのポートを切断
  disconnectAll();

  super.exit();
}
