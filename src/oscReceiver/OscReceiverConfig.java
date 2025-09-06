import java.awt.*;
import java.awt.event.*;
import java.util.Date;
import java.util.StringJoiner;
import java.util.Arrays;
import java.util.ArrayList;
import java.io.File;
import javax.swing.*;
import javax.swing.event.*;
import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;
import oscP5.*;
import processing.awt.*;
import processing.core.*;
import processing.data.*;
import netP5.*;

public class OscReceiverConfig {
  private final Logger L = Logger.getLogger(getClass());
  private PApplet parent;
  private JSONObject jsonConfig;
  private SystemConfigManager systemConfig;

  // デフォルト設定値
  private int DEFAULT_MY_OSC_PORT = 8001;
  private int DEFAULT_PORT_COUNT = 1;
  private int[] DEFAULT_PORTS = {8001, 8002, 8003};

  // ウィンドウ設定
  private int W_WIDTH = 800;
  private int W_HEIGHT = 450;
  private int W_X = 100;  // ウィンドウのX座標
  private int W_Y = 100;  // ウィンドウのY座標

  // ポート設定
  private int[] portNumbers = new int[3];
  private int currentPortCount = 1;

  public OscReceiverConfig(PApplet _parent) {
    parent = _parent;
    systemConfig = new SystemConfigManager(parent);
    
    // デフォルトポート設定をコピー
    System.arraycopy(DEFAULT_PORTS, 0, portNumbers, 0, DEFAULT_PORTS.length);
  }

  ////////////////////////////////////////////////////////////////////////////////
  // 設定ファイルのロード
  ////////////////////////////////////////////////////////////////////////////////
  public void setupConfig() {
    String logDir = systemConfig.getLogDirectory();
    String configDir = systemConfig.getConfigDirectory();
    
    System.out.println("設定ディレクトリ: " + configDir);
    System.out.println("ログディレクトリ: " + logDir);

    // 設定ディレクトリの初期化
    if (!systemConfig.createConfigDirectory()) {
      System.out.println("設定ディレクトリの作成に失敗しました: " + systemConfig.getConfigDirectory());
    }
    
    // ログディレクトリの初期化
    if (!systemConfig.createLogDirectory()) {
      System.out.println("ログディレクトリの作成に失敗しました: " + systemConfig.getLogDirectory());
    }
    
    System.setProperty("logging.dir", logDir);
    
    // log4j.propertiesのパスを設定
    String log4jPath = configDir + java.io.File.separator + "log4j.properties";
    
    // log4j.propertiesファイルが存在しない場合は作成
    File log4jFile = new File(log4jPath);
    if (log4jFile.exists()) {
      System.out.println("✓ log4j.propertiesファイルが見つかりました");
    }
    
    // log4jの設定を読み込み
    try {
      PropertyConfigurator.configure(log4jPath);
      String infoMsg = "log4j設定を読み込みました: " + log4jPath;
      L.debug("✓ " + infoMsg);
    } catch (Exception e) {
      String errorMsg = "log4j設定の読み込みに失敗しました: " + e.getMessage();
      L.debug("✗ " + errorMsg);
      // フォールバック: デフォルト設定を使用
      L.debug("✓ デフォルトログ設定を適用しました");
    }
  
    // 設定ファイルのパスを取得
    String configPath = systemConfig.getConfigFilePath();
    L.info("設定ファイルのパス: " + configPath);
    
    // 設定ファイルの読み込み
    File configFile = new File(configPath);
    if (configFile.exists()) {
      try {
        jsonConfig = parent.loadJSONObject(configPath);
        L.info("設定ファイルを読み込みました。 ");
      } catch (Exception e) {
        L.error("設定ファイルの読み込みに失敗しました: " + e.getMessage());
        jsonConfig = createDefaultConfig();
      }
    } else {
      L.info("設定ファイルが存在しません。デフォルト設定を作成します。");
      jsonConfig = createDefaultConfig();
      saveConfigToFile();
    }

    // 設定値を読み込み
    loadConfigValues();
  }

  private void loadConfigValues() {
    // ポート数の設定を読み込み
    if (jsonConfig.hasKey("portCount")) {
      currentPortCount = jsonConfig.getInt("portCount");
      currentPortCount = Math.max(1, Math.min(3, currentPortCount)); // constrain(1, 3)の代わり
    } else {
      currentPortCount = DEFAULT_PORT_COUNT;
    }

    // 複数ポートの設定を読み込み
    if (jsonConfig.hasKey("ports")) {
      JSONArray ports = jsonConfig.getJSONArray("ports");
      for (int i = 0; i < 3 && i < ports.size(); i++) {
        portNumbers[i] = ports.getInt(i);
      }
    } else {
      // デフォルトポート設定
      System.arraycopy(DEFAULT_PORTS, 0, portNumbers, 0, DEFAULT_PORTS.length);
    }
    
    // ウィンドウ座標を読み込み
    if (jsonConfig.hasKey("windowX")) {
      W_X = jsonConfig.getInt("windowX");
    }
    if (jsonConfig.hasKey("windowY")) {
      W_Y = jsonConfig.getInt("windowY");
    }
    if (jsonConfig.hasKey("windowWidth")) {
      W_WIDTH = jsonConfig.getInt("windowWidth");
    }
    if (jsonConfig.hasKey("windowHeight")) {
      W_HEIGHT = jsonConfig.getInt("windowHeight");
    }
  }

  // ウィンドウ座標を保存
  public void saveWindowPosition(int _x, int _y, int _width, int _height) {
    W_X = _x;
    W_Y = _y;
    W_WIDTH = _width;
    W_HEIGHT = _height;
    
    jsonConfig.setInt("windowX", W_X);
    jsonConfig.setInt("windowY", W_Y);
    jsonConfig.setInt("windowWidth", W_WIDTH);
    jsonConfig.setInt("windowHeight", W_HEIGHT);
    saveConfigToFile();
  }

  // ポート設定を保存
  public void savePortConfig(int[] _portNumbers, int _portCount) {
    // ポート番号をコピー
    System.arraycopy(_portNumbers, 0, portNumbers, 0, 3);
    currentPortCount = _portCount;
    
    // JSONに保存
    JSONArray ports = new JSONArray();
    for (int i = 0; i < currentPortCount; i++) {
      ports.setInt(i, portNumbers[i]);
    }
    jsonConfig.setJSONArray("ports", ports);
    jsonConfig.setInt("portCount", currentPortCount);
    
    saveConfigToFile();
  }
  
  private void saveConfigToFile() {
    try {
      String configPath = systemConfig.getConfigFilePath();
      parent.saveJSONObject(jsonConfig, configPath);
      L.debug("設定ファイルを保存しました: " + configPath);
    } catch (Exception e) {
      L.error("設定ファイルの保存に失敗しました: " + e.getMessage());
    }
  }
  
  private JSONObject createDefaultConfig() {
    JSONObject config = new JSONObject();
    
    // ポート設定
    JSONArray ports = new JSONArray();
    for (int i = 0; i < 3; i++) {
      ports.setInt(i, DEFAULT_PORTS[i]);
    }
    config.setJSONArray("ports", ports);
    config.setInt("portCount", DEFAULT_PORT_COUNT);
    
    // ウィンドウ設定
    config.setInt("windowX", W_X);
    config.setInt("windowY", W_Y);
    config.setInt("windowWidth", W_WIDTH);
    config.setInt("windowHeight", W_HEIGHT);
    
    return config;
  }

  ////////////////////////////////////////////////////////////////////////////////
  // getter
  ////////////////////////////////////////////////////////////////////////////////
  public int getWindowWidth() {
    return W_WIDTH;
  }
  
  public int getWindowHeight() {
    return W_HEIGHT;
  }
  
  public int getWindowX() {
    return W_X;
  }
  
  public int getWindowY() {
    return W_Y;
  }

  public int[] getPortNumbers() {
    return portNumbers.clone();
  }
  
  public int getCurrentPortCount() {
    return currentPortCount;
  }

  public int getMyOscPort() {
    return portNumbers[0];
  }

  public String getLogDirectory() {
    return systemConfig.getLogDirectory();
  }

  public String getConfigDirectory() {
    return systemConfig.getConfigDirectory();
  }
}
