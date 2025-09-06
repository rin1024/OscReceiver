import java.io.File;
import processing.core.PApplet;

/**
 * システム設定ディレクトリの管理クラス
 * Processing IDEとアプリ実行時に適切な設定ディレクトリを提供します
 */
public class SystemConfigManager {
  private static final String APP_NAME = "OscReceiver";
  private PApplet parent;

  public SystemConfigManager(PApplet _parent) {
    parent = _parent;
  }

  /**
   * Processing IDEで実行されているかどうかを判定
   * @return Processing IDEで実行されている場合true
   */
  private boolean isRunningInProcessingIDE() {
    try {
      // 1. dataPath()の文字列でアプリ実行を判定（最も確実）
      String dataPath = parent.dataPath("");
      boolean isExportedApp = dataPath.contains(".app/Contents/Java/data");
      //System.out.println("デバッグ - dataPath: " + dataPath);
      //System.out.println("デバッグ - exportしたアプリ判定: " + isExportedApp);
      
      if (isExportedApp) {
        //System.out.println("デバッグ - exportしたアプリと判定、Processing IDEではない");
        return false;
      }

      return !isExportedApp;
    }
    catch (Exception e) {
      System.out.println("デバッグ - エラー発生: " + e.getMessage());
      // エラーが発生した場合は安全側に倒してアプリ実行と判定
      return false;
    }
  }

  /**
   * Processing IDE用の設定ディレクトリを取得
   * @return dataフォルダ内の設定ディレクトリのパス
   */
  private String getProcessingConfigDirectory() {
    return parent.dataPath("");
  }

  /**
   * アプリ実行用のシステム設定ディレクトリを取得
   * @return OS別の適切な設定ディレクトリのパス
   */
  private String getSystemConfigDirectory() {
    String os = System.getProperty("os.name").toLowerCase();

    if (os.contains("win")) {
      // Windows: %APPDATA%\OscReceiver\
      String appData = System.getenv("APPDATA");
      if (appData != null) {
        return appData + File.separator + APP_NAME;
      }
    } else if (os.contains("mac")) {
      // macOS: ~/Library/Application Support/OscReceiver/
      return System.getProperty("user.home") + File.separator +
        "Library" + File.separator + "Application Support" + File.separator + APP_NAME;
    } else if (os.contains("nix") || os.contains("nux") || os.contains("aix")) {
      // Linux: ~/.config/OscReceiver/
      return System.getProperty("user.home") + File.separator +
        ".config" + File.separator + APP_NAME;
    }

    // フォールバック: ユーザーホームディレクトリ
    return System.getProperty("user.home") + File.separator + "." + APP_NAME.toLowerCase();
  }

  /**
   * 実行環境に応じた適切な設定ディレクトリを取得
   * Processing IDEで実行されている場合はdataフォルダ、アプリ実行時はシステムフォルダを使用
   * @return 設定ディレクトリのパス
   */
  public String getConfigDirectory() {
    boolean isIDE = isRunningInProcessingIDE();
    String configDir;

    if (isIDE) {
      configDir = getProcessingConfigDirectory();
    } else {
      configDir = getSystemConfigDirectory();
    }

    // デバッグ情報を出力（本番環境では削除可能）
    //System.out.println("実行環境判定: " + (isIDE ? "Processing IDE" : "アプリ実行"));
    //System.out.println("設定ディレクトリ: " + configDir);

    return configDir;
  }

  /**
   * 設定ファイルのパスを取得
   * @return config.jsonのフルパス
   */
  public String getConfigFilePath() {
    return getConfigDirectory() + File.separator + "config.json";
  }

  /**
   * ログディレクトリのパスを取得
   * @return ログディレクトリのパス
   */
  public String getLogDirectory() {
    boolean isIDE = isRunningInProcessingIDE();
    if (isIDE) {
      return parent.sketchPath("log");
    }
    return getSystemConfigDirectory() + File.separator + "log";
  }

  /**
   * 設定ディレクトリが存在するかチェック
   * @return 存在する場合true
   */
  public boolean configDirectoryExists() {
    File dir = new File(getConfigDirectory());
    return dir.exists();
  }

  /**
   * 設定ディレクトリを作成
   * @return 作成に成功した場合true
   */
  public boolean createConfigDirectory() {
    File dir = new File(getConfigDirectory());
    if (!dir.exists()) {
      return dir.mkdirs();
    }
    return true;
  }

  /**
   * ログディレクトリを作成
   * @return 作成に成功した場合true
   */
  public boolean createLogDirectory() {
    File dir = new File(getLogDirectory());
    if (!dir.exists()) {
      return dir.mkdirs();
    }
    return true;
  }
}
