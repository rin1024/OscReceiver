# リモートリポジトリ連携

## Git操作のベストプラクティス

### 基本的なワークフロー
```bash
# 1. 最新の変更を取得
git fetch origin
git pull origin main

# 2. 作業ブランチの作成
git checkout -b feature/osc-improvement

# 3. 変更のコミット
git add .
git commit -m "feat: OSC接続の安定性を向上

- ポート変更時の再接続処理を追加
- エラーハンドリングを強化
- ログ出力を改善"

# 4. リモートブランチへのプッシュ
git push origin feature/osc-improvement

# 5. プルリクエストの作成（GitHub/GitLab）
# 6. コードレビュー後のマージ
```

### コミットメッセージの規約
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type**:
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント更新
- `style`: コードスタイルの変更
- `refactor`: リファクタリング
- `test`: テストの追加・修正
- `chore`: ビルドプロセス・ツールの変更

**例**:
```
feat(osc): ポート変更時の自動再接続機能を追加

- 設定変更時にOSCサーバーを自動的に再起動
- ユーザー体験の向上
- エラーログの詳細化

Closes #123
```

## ブランチ戦略

### メインブランチ
- **`main`**: 本番環境用の安定版
- **`develop`**: 開発用の統合ブランチ

### 作業ブランチ
- **`feature/*`**: 新機能開発
- **`bugfix/*`**: バグ修正
- **`hotfix/*`**: 緊急修正
- **`release/*`**: リリース準備

### ブランチ命名規則
```bash
# 機能開発
feature/osc-connection-improvement
feature/gui-enhancement
feature/logging-system

# バグ修正
bugfix/port-binding-error
bugfix/gui-layout-issue

# 緊急修正
hotfix/critical-connection-bug
hotfix/security-vulnerability

# リリース準備
release/v1.2.0
```

## プルリクエスト/マージリクエスト

### テンプレート
```markdown
## 概要
このPRで実装する機能・修正の概要を簡潔に説明してください。

## 変更内容
- [ ] 新機能の追加
- [ ] バグ修正
- [ ] ドキュメント更新
- [ ] テスト追加

## 技術的な詳細
実装の詳細や技術的な判断について説明してください。

## テスト
- [ ] 単体テスト
- [ ] 統合テスト
- [ ] 手動テスト

## チェックリスト
- [ ] コードレビューが完了している
- [ ] テストが通っている
- [ ] ドキュメントが更新されている
- [ ] コミットメッセージが適切である

## 関連Issue
Closes #123
Related to #456
```

### レビューのポイント
1. **コードの品質**: 可読性、保守性
2. **セキュリティ**: 脆弱性の有無
3. **パフォーマンス**: 効率性
4. **テスト**: カバレッジ、品質
5. **ドキュメント**: 更新の必要性

## CI/CD設定

### GitHub Actions設定例
```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Java
      uses: actions/setup-java@v3
      with:
        java-version: '8'
        distribution: 'temurin'
    
    - name: Cache dependencies
      uses: actions/cache@v3
      with:
        path: ~/.m2
        key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
        restore-keys: ${{ runner.os }}-m2
    
    - name: Run tests
      run: mvn test
    
    - name: Build application
      run: mvn clean compile
```

### GitLab CI設定例
```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

variables:
  MAVEN_OPTS: "-Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository"

cache:
  paths:
    - .m2/repository

test:
  stage: test
  image: openjdk:8
  script:
    - mvn test
  artifacts:
    reports:
      junit: target/surefire-reports/TEST-*.xml

build:
  stage: build
  image: openjdk:8
  script:
    - mvn clean compile
  artifacts:
    paths:
      - target/
    expire_in: 1 week

deploy:
  stage: deploy
  image: openjdk:8
  script:
    - echo "Deploy to production"
  only:
    - main
```

## セキュリティ設定

### シークレット管理
```bash
# 環境変数での機密情報管理
export OSC_API_KEY="your-secret-key"
export DATABASE_PASSWORD="your-db-password"

# .envファイル（.gitignoreに追加）
OSC_API_KEY=your-secret-key
DATABASE_PASSWORD=your-db-password
```

### .gitignore設定
```gitignore
# 機密情報
.env
*.key
*.pem
*.p12

# ログファイル
*.log
log/

# 設定ファイル（機密情報を含む場合）
config/local.json
config/production.json

# 依存関係
node_modules/
*.jar
!lib/*.jar

# IDE設定
.vscode/
.idea/
*.iml

# OS生成ファイル
.DS_Store
Thumbs.db

# 一時ファイル
*.tmp
*.temp
```

## リリース管理

### バージョニング
**セマンティックバージョニング**:
- **MAJOR**: 互換性のない変更
- **MINOR**: 後方互換性のある新機能
- **PATCH**: 後方互換性のあるバグ修正

**例**: `1.2.3`

### リリースノート
```markdown
# Release Notes v1.2.0

## 新機能
- OSC接続の自動再接続機能
- ログレベルの動的変更
- 設定ファイルのホットリロード

## 改善
- GUIのレスポンシブ性向上
- エラーメッセージの詳細化
- パフォーマンスの最適化

## バグ修正
- ポート変更時のクラッシュ修正
- ログファイルのローテーション問題解決

## 破壊的変更
なし

## 依存関係の更新
- oscP5: 0.3.5 → 0.3.6
- log4j: 1.2.17 → 1.2.18
```

## トラブルシューティング

### よくある問題と解決策

#### マージコンフリクト
```bash
# コンフリクトの解決
git status  # コンフリクトファイルの確認
# ファイルを編集してコンフリクトを解決
git add .   # 解決済みファイルを追加
git commit  # マージコミット
```

#### リモートブランチの削除
```bash
# リモートブランチの削除
git push origin --delete feature/old-feature

# ローカルブランチの削除
git branch -d feature/old-feature
```

#### コミットの取り消し
```bash
# 直前のコミットを取り消し（変更は保持）
git reset --soft HEAD~1

# 直前のコミットを完全に削除
git reset --hard HEAD~1

# 特定のコミットまで戻る
git reset --hard <commit-hash>
```

## 更新履歴

- **2024-12-19**: 初期テンプレート作成
- **対象**: Git操作、ブランチ戦略、PR/MR、CI/CD、セキュリティ、リリース管理

