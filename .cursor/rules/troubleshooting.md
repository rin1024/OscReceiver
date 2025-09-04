# トラブルシューティングガイド

## OSC接続の問題

### ポートが使用中エラー
**症状**: `java.net.BindException: Address already in use`

**原因**: 指定したポートが他のアプリケーションで使用されている

**解決策**:
1. 別のポート番号を試す
2. 使用中のポートを確認:
   ```bash
   # macOS/Linux
   lsof -i :8081
   
   # Windows
   netstat -an | findstr 8081
   ```
3. 使用中のプロセスを終了する

**予防策**: 設定ファイルでポート番号を変更可能にする

### OSCメッセージが受信されない
**症状**: アプリケーションは起動するが、OSCメッセージが表示されない

**原因**:
- ポート番号の不一致
- ファイアウォールの設定
- OSCクライアントの設定ミス

**解決策**:
1. ポート番号を確認
2. ファイアウォールでポートを開放
3. OSCクライアントの設定を確認
4. ログで接続状況を確認

**確認方法**:
```java
// 接続状態のログ出力
L.info("OSC server listening on port: " + MY_OSC_PORT);
```

## GUI表示の問題

### Swingコンポーネントが表示されない
**症状**: ボタンやテキストフィールドが画面に表示されない

**原因**: 
- コンポーネントの境界設定が不適切
- 親コンテナへの追加が失敗
- Z-orderの問題

**解決策**:
1. 境界設定の確認
   ```java
   // デバッグ用の境界表示
   System.out.println("Component bounds: " + component.getBounds());
   ```
2. 親コンテナの確認
   ```java
   // 親コンテナの階層を確認
   Container parent = component.getParent();
   while (parent != null) {
     System.out.println("Parent: " + parent.getClass().getName());
     parent = parent.getParent();
   }
   ```

### レイアウトが崩れる
**症状**: ウィンドウサイズ変更時にコンポーネントの配置が崩れる

**原因**: 絶対座標での配置

**解決策**:
1. レイアウトマネージャーの使用
2. 相対座標での配置
3. リサイズイベントの処理

## ログ出力の問題

### ログファイルが作成されない
**症状**: ログファイルが生成されない、または書き込み権限エラー

**原因**:
- ディレクトリの存在しない
- 書き込み権限の不足
- パスの設定ミス

**解決策**:
1. ログディレクトリの存在確認
   ```java
   File logDir = new File(dataPath("../log/"));
   if (!logDir.exists()) {
     logDir.mkdirs();
   }
   ```
2. パスの確認
   ```java
   L.info("Log directory: " + dataPath("../log/"));
   L.info("Log4j config: " + dataPath("log4j.properties"));
   ```

### ログレベルが適切でない
**症状**: 必要なログが出力されない、または大量のログが出力される

**解決策**: log4j.propertiesの設定調整
```properties
# ログレベルの設定例
log4j.rootLogger=INFO, file, console
log4j.logger.oscReceiver=DEBUG
```

## 設定ファイルの問題

### config.jsonが読み込めない
**症状**: 設定が読み込まれず、デフォルト値が使用される

**原因**:
- ファイルが存在しない
- JSON形式が不正
- ファイルパスの問題

**解決策**:
1. ファイルの存在確認
2. JSON形式の検証
3. デフォルト値の設定
4. エラーハンドリングの実装

**実装例**:
```java
void loadConfig() {
  try {
    File configFile = new File(dataPath("config.json"));
    if (!configFile.exists()) {
      createDefaultConfig();
    }
    config = loadJSONObject("config.json");
    MY_OSC_PORT = config.getInt("myOscPort", 8081);
  } catch (Exception e) {
    L.error("Config load failed: " + e.getMessage());
    MY_OSC_PORT = 8081; // デフォルト値
  }
}
```

## パフォーマンスの問題

### メモリ使用量が増加する
**症状**: 長時間実行時にメモリ使用量が増加し続ける

**原因**:
- ログ履歴の蓄積
- イベントリスナーの重複登録
- リソースの適切な解放不足

**解決策**:
1. ログ履歴のサイズ制限
2. イベントリスナーの適切な管理
3. リソースの明示的な解放

### アプリケーションが重くなる
**症状**: OSCメッセージ受信時にUIが重くなる

**原因**:
- メインスレッドでの重い処理
- ログ表示の更新頻度が高い

**解決策**:
1. バックグラウンドスレッドでの処理
2. ログ表示の更新頻度制限
3. バッチ処理の実装

## 一般的なデバッグ手法

### ログレベルの調整
```java
// 開発時はDEBUGレベル、本番時はINFOレベル
if (isDevelopmentMode()) {
  L.setLevel(Level.DEBUG);
} else {
  L.setLevel(Level.INFO);
}
```

### 状態の可視化
```java
// 接続状態の表示
void draw() {
  background(bgColor);
  
  // 接続状態の表示
  fill(connected ? color(0, 255, 0) : color(255, 0, 0));
  ellipse(50, 50, 20, 20);
  
  // ポート番号の表示
  fill(0);
  text("Port: " + MY_OSC_PORT, 20, 80);
}
```

### エラーの詳細情報取得
```java
// スタックトレースの出力
try {
  // 問題のある処理
} catch (Exception e) {
  L.error("Error occurred", e);
  e.printStackTrace();
}
```

## 更新履歴

- **2024-12-19**: 初期テンプレート作成
- **対象問題**: OSC接続、GUI表示、ログ出力、設定ファイル、パフォーマンス、デバッグ手法

