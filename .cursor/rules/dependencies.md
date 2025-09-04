# 依存関係とAPI使用例

## 主要ライブラリ

### oscP5.jar - OSC通信ライブラリ

#### 基本設定
```java
import oscP5.*;

// OSCサーバーの初期化
OscP5 oscP5 = new OscP5(this, portNumber);

// OSCクライアントの初期化（送信用）
OscP5 oscClient = new OscP5(this, "127.0.0.1", 8081);
```

#### OSCメッセージの受信
```java
// メッセージ受信イベントハンドラー
void oscEvent(OscMessage theOscMessage) {
  // アドレスパターンの取得
  String addrPattern = theOscMessage.addrPattern();
  
  // タイプタグの取得（データ型情報）
  String typetag = theOscMessage.typetag();
  
  // 引数の取得
  Object[] arguments = theOscMessage.arguments();
  
  // 特定の型での取得
  if (theOscMessage.checkTypetag("i")) { // integer
    int value = theOscMessage.get(0).intValue();
  } else if (theOscMessage.checkTypetag("f")) { // float
    float value = theOscMessage.get(0).floatValue();
  } else if (theOscMessage.checkTypetag("s")) { // string
    String value = theOscMessage.get(0).stringValue();
  }
}
```

#### OSCメッセージの送信
```java
// 単純なメッセージの送信
OscMessage msg = new OscMessage("/test");
msg.add("Hello OSC");
oscClient.send(msg);

// 数値データの送信
OscMessage dataMsg = new OscMessage("/data");
dataMsg.add(42);
dataMsg.add(3.14f);
dataMsg.add("value");
oscClient.send(dataMsg);

// バンドルでの複数メッセージ送信
OscBundle bundle = new OscBundle();
bundle.add(msg);
bundle.add(dataMsg);
oscClient.send(bundle);
```

#### ポート管理
```java
// ポートの変更
void changePort(int newPort) {
  if (oscP5 != null) {
    oscP5.stop();
  }
  oscP5 = new OscP5(this, newPort);
  MY_OSC_PORT = newPort;
}

// 接続状態の確認
boolean isConnected() {
  return oscP5 != null;
}
```

### log4j.jar - ログ管理ライブラリ

#### 基本設定
```java
import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;
import org.apache.log4j.Level;

// ロガーの取得
final Logger L = Logger.getLogger(getClass());

// 設定ファイルの読み込み
PropertyConfigurator.configure(dataPath("log4j.properties"));

// ログレベルの設定
L.setLevel(Level.DEBUG);
```

#### ログ出力レベル
```java
// トレースレベル（最も詳細）
L.trace("Detailed trace information");

// デバッグレベル（開発時の詳細情報）
L.debug("Debug information: " + variable);

// 情報レベル（一般的な情報）
L.info("Application started on port " + port);

// 警告レベル（注意が必要な状況）
L.warn("Port " + port + " is already in use");

// エラーレベル（エラーが発生した状況）
L.error("Failed to start OSC server", exception);

// 致命的レベル（アプリケーションが継続できない状況）
L.fatal("Critical system error", exception);
```

#### 構造化ログ出力
```java
// 例外情報を含むログ
try {
  riskyOperation();
} catch (Exception e) {
  L.error("Operation failed", e);
}

// パラメータ付きログ
L.info("OSC message received: {} [{}] {}", 
  addrPattern, typetag, Arrays.toString(arguments));

// パフォーマンス測定
long startTime = System.currentTimeMillis();
// ... 処理 ...
long duration = System.currentTimeMillis() - startTime;
L.info("Operation completed in {} ms", duration);
```

### Swing/AWT - GUIライブラリ

#### 基本コンポーネント
```java
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

// テキストフィールド
JTextField textField = new JTextField();
textField.setText("8081");
textField.setBounds(20, 10, 150, 30);

// ボタン
JButton button = new JButton("Connect");
button.setBounds(180, 10, 150, 30);
button.addActionListener(actionListener);

// ラベル
JLabel label = new JLabel("Port Number");
label.setBounds(20, 40, 150, 20);

// テキストエリア
JTextArea textArea = new JTextArea();
textArea.setLineWrap(true);
textArea.setEditable(false);
```

#### レイアウト管理
```java
// スクロールパネル
JScrollPane scrollPane = new JScrollPane(
  textArea,
  JScrollPane.VERTICAL_SCROLLBAR_ALWAYS,
  JScrollPane.HORIZONTAL_SCROLLBAR_AS_NEEDED
);
scrollPane.setPreferredSize(new Dimension(450, 400));

// 境界設定
scrollPane.setBounds(20, 70, 680, height - 90);
```

#### イベント処理
```java
// アクションリスナー
public class GuiListener implements ActionListener {
  @Override
  public void actionPerformed(ActionEvent e) {
    String command = e.getActionCommand();
    if ("Connect".equals(command)) {
      handleConnect();
    } else if ("Clear".equals(command)) {
      handleClear();
    }
  }
}

// キーリスナー
public class GuiListener implements KeyListener {
  @Override
  public void keyPressed(KeyEvent e) {
    if (e.getKeyCode() == KeyEvent.VK_ENTER) {
      handleEnterKey();
    }
  }
  
  @Override
  public void keyTyped(KeyEvent e) {}
  
  @Override
  public void keyReleased(KeyEvent e) {}
}
```

### Processing - メインアプリケーションフレームワーク

#### ライフサイクルメソッド
```java
// アプリケーション開始時（一度だけ実行）
void setup() {
  // 初期化処理
  size(720, 410);
  setupGUI();
  loadConfig();
}

// 描画ループ（継続的に実行）
void draw() {
  background(bgColor);
  // 描画処理
}

// 設定（setup()の前に実行）
void settings() {
  // ウィンドウサイズなどの設定
  size(W_WIDTH, W_HEIGHT);
}
```

#### ファイル操作
```java
// JSONファイルの読み込み
JSONObject config = loadJSONObject("config.json");

// JSONファイルの保存
saveJSONObject(config, "data/config.json");

// データパスの取得
String dataPath = dataPath("config.json");
String logPath = dataPath("../log/");
```

#### ユーティリティ関数
```java
// 日付フォーマット
String getFormattedDate() {
  DateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  return dateFormat.format(new Date());
}

// 色の生成
int bgColor = color(240, 240, 240);
int textColor = color(0, 0, 0);
```

## 設定ファイル

### log4j.properties
```properties
# ルートロガーの設定
log4j.rootLogger=INFO, file, console

# ファイルアペンダーの設定
log4j.appender.file=org.apache.log4j.RollingFileAppender
log4j.appender.file.File=${logging.dir}/log4j-application.log
log4j.appender.file.MaxFileSize=10MB
log4j.appender.file.MaxBackupIndex=5
log4j.appender.file.layout=org.apache.log4j.PatternLayout
log4j.appender.file.layout.ConversionPattern=%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m%n

# コンソールアペンダーの設定
log4j.appender.console=org.apache.log4j.ConsoleAppender
log4j.appender.console.layout=org.apache.log4j.PatternLayout
log4j.appender.console.layout.ConversionPattern=%d{HH:mm:ss} %-5p %c{1}:%L - %m%n

# アプリケーション固有のログレベル
log4j.logger.oscReceiver=DEBUG
```

### config.json
```json
{
  "myOscPort": 8081,
  "logLevel": "INFO",
  "maxLogEntries": 1000,
  "autoReconnect": true
}
```

## 依存関係の管理

### ライブラリの配置
```
src/oscReceiver/code/
├── oscP5.jar          # OSC通信ライブラリ
├── log4j.jar          # ログ管理ライブラリ
└── log4j.properties   # ログ設定ファイル
```

### クラスパスの設定
Processing IDEでは、`code/` フォルダ内のJARファイルが自動的にクラスパスに追加されます。

### バージョン管理
- **oscP5**: 最新版（互換性を確認）
- **log4j**: 1.2.x系（安定版）
- **Processing**: 3.x系

## 更新履歴

- **2024-12-19**: 初期テンプレート作成
- **対象ライブラリ**: oscP5, log4j, Swing/AWT, Processing
- **内容**: 基本設定、API使用例、設定ファイル、依存関係管理

