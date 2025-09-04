# 実装パターンとベストプラクティス

## OSC通信パターン

### OSCサーバー初期化
```java
// 推奨パターン
OscP5 oscP5 = new OscP5(this, MY_OSC_PORT);

// ポート設定の動的変更
void changePort(int newPort) {
  if (oscP5 != null) {
    oscP5.stop();
  }
  oscP5 = new OscP5(this, newPort);
  MY_OSC_PORT = newPort;
}
```

### OSCメッセージ受信ハンドラー
```java
// 標準的なOSCメッセージ受信パターン
void oscEvent(OscMessage theOscMessage) {
  String addrPattern = theOscMessage.addrPattern();
  String typetag = theOscMessage.typetag();
  
  // アドレスパターンによる分岐処理
  switch(addrPattern) {
    case "/test":
      handleTestMessage(theOscMessage);
      break;
    case "/data":
      handleDataMessage(theOscMessage);
      break;
    default:
      L.warn("Unknown OSC address: " + addrPattern);
  }
}
```

## GUI構築パターン

### Swingコンポーネントの配置
```java
// 推奨：JLayeredPaneを使用した柔軟なレイアウト
Canvas canvas = (Canvas)surface.getNative();
JLayeredPane pane = (JLayeredPane)canvas.getParent().getParent();

// コンポーネントの境界設定
JTextField textField = new JTextField();
textField.setBounds(x, y, width, height);
pane.add(textField);
```

### イベントリスナーの実装
```java
// 推奨：専用クラスでのイベント処理
public class GuiListener implements ActionListener, KeyListener {
  private final PApplet parent;
  
  public GuiListener(PApplet parent) {
    this.parent = parent;
  }
  
  @Override
  public void actionPerformed(ActionEvent e) {
    // イベント処理ロジック
  }
}
```

## ログ管理パターン

### Log4j設定と初期化
```java
// 推奨：データパスを使用した相対パス設定
void setupLogging() {
  System.setProperty("logging.dir", dataPath("../log/"));
  PropertyConfigurator.configure(dataPath("log4j.properties"));
  
  // ログ出力の例
  L.info("Application started");
  L.debug("Configuration loaded: " + config.toString());
}
```

### 構造化ログ出力
```java
// 推奨：意味のあるログメッセージ
void logOscMessage(OscMessage msg) {
  L.info(String.format("OSC received: %s [%s] %s", 
    msg.addrPattern(), 
    msg.typetag(), 
    Arrays.toString(msg.arguments())));
}

void logConnectionStatus(boolean connected, int port) {
  if (connected) {
    L.info("OSC server started on port " + port);
  } else {
    L.warn("Failed to start OSC server on port " + port);
  }
}
```

## 設定管理パターン

### JSON設定ファイルの読み込み
```java
// 推奨：エラーハンドリング付き設定読み込み
void loadConfig() {
  try {
    config = loadJSONObject("config.json");
    MY_OSC_PORT = config.getInt("myOscPort", 8081); // デフォルト値付き
    L.info("Configuration loaded successfully");
  } catch (Exception e) {
    L.error("Failed to load config.json: " + e.getMessage());
    // デフォルト設定を使用
    MY_OSC_PORT = 8081;
  }
}
```

### 設定の動的更新
```java
// 推奨：設定変更時の再初期化
void updateConfig(int newPort) {
  MY_OSC_PORT = newPort;
  if (connected) {
    reconnect();
  }
  saveConfig();
}

void saveConfig() {
  try {
    config.setInt("myOscPort", MY_OSC_PORT);
    saveJSONObject(config, "data/config.json");
    L.info("Configuration saved");
  } catch (Exception e) {
    L.error("Failed to save configuration: " + e.getMessage());
  }
}
```

## エラーハンドリングパターン

### 例外処理の基本
```java
// 推奨：適切なログレベルでのエラー記録
try {
  // 危険な操作
  riskyOperation();
} catch (IOException e) {
  L.error("IO error occurred: " + e.getMessage(), e);
  showUserMessage("ファイル操作でエラーが発生しました");
} catch (Exception e) {
  L.error("Unexpected error: " + e.getMessage(), e);
  showUserMessage("予期しないエラーが発生しました");
}
```

### ユーザーへのフィードバック
```java
// 推奨：ログとユーザー表示の両方
void showUserMessage(String message) {
  logText.add(0, "[" + getFormattedDate() + "] " + message);
  updateLogDisplay();
  L.info("User message: " + message);
}
```

## パフォーマンス最適化パターン

### メモリ管理
```java
// 推奨：ログ履歴のサイズ制限
void addLogEntry(String entry) {
  logText.add(0, "[" + getFormattedDate() + "] " + entry);
  
  // ログ履歴のサイズ制限（メモリリーク防止）
  if (logText.size() > 1000) {
    logText.subList(1000, logText.size()).clear();
  }
}
```

### 効率的な文字列処理
```java
// 推奨：StringJoinerを使用した効率的な文字列結合
void updateLogDisplay() {
  StringJoiner joiner = new StringJoiner("\r\n");
  for (String log : logText) {
    joiner.add(log);
  }
  logTextArea.setText(joiner.toString());
}
```

## 更新履歴

- **2024-12-19**: 初期テンプレート作成
- **パターン**: OSC通信、GUI構築、ログ管理、設定管理、エラーハンドリング、パフォーマンス最適化

