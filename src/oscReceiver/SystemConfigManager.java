import java.io.File;

/**
 * システム設定ディレクトリの管理クラス
 * OS別に適切な設定ディレクトリを提供します
 */
public class SystemConfigManager {
    private static final String APP_NAME = "OscReceiver";
    
    /**
     * OS別の適切な設定ディレクトリを取得
     * @return 設定ディレクトリのパス
     */
    public String getConfigDirectory() {
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
        return getConfigDirectory() + File.separator + "logs";
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
