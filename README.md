# tash の dotfiles

Apple Silicon Mac の**ユーザー環境**を Nix + standalone Home Manager で管理するリポジトリです。OS 全体は管理しません。Nix を全部覚える必要はありません。まず「一つの設定の管理元 → 読み込み → 配置先 → 確認 → 適用 → 復旧」を説明できれば十分です。

**明日の朝は、ここを読んでから [レビューと優先課題](docs/review.md) の P1 を確認してください。まだ `./apply.sh` は実行しません。** 引数なしは実際のホームを変更します。今回のレビューでは実機適用を行っていません。

## 最初に知る地図

```text
flake.lock ── 依存の固定版
     ↓
flake.nix ── Apple Silicon / パッケージ集合 / default 設定の入口
     ├── local.nix     ユーザー名（自分で作る・Git 管理外）
     ├── home.nix      パッケージ + 配置先
     └── private.nix   任意の追加 module（Git 管理外）
              ↓ Home Manager が評価・ビルド
       generation（適用可能な環境一式）
              ↓ switch 時だけホームに反映
       ~/.zshrc、~/.config/nvim/init.lua など
```

`apply.sh build` は generation を作り、`result` を置きます。依存の取得やビルドは起きますが、ホーム設定を有効化しません。`apply.sh switch`（引数なしも同じ）はそれに加え、ユーザーのプロファイル・管理対象ファイルを変更します。両方ともローカル設定を含む一時コピーを作ります。**Git 管理外は暗号化・秘密保管を意味しません。Nix に渡すファイルは store に残り得るため、トークンやパスワードを書きません。** 詳細は [運用手順](docs/operations.md)。

| 編集するファイル | 責任・読み込み元 | 配置先・影響 |
|---|---|---|
| `flake.nix` / `flake.lock` | 依存・ホスト・module の組み立て / 固定版 | 設定評価全体。日常の alias 編集では触らない |
| `home.nix` | `flake.nix` から渡される Home Manager module | パッケージと以下のリンク |
| `shell/zprofile` | ログイン zsh の環境 | `~/.zprofile` |
| `shell/zshrc` | 対話 zsh、外部ツール初期化 | `~/.zshrc` |
| `shell/aliases.zsh` / `shell/herdr.zsh` | `.zshrc` から source | `~/.config/shell/` の同名ファイル |
| `nvim/init.lua` | Neovim の起動設定 | `~/.config/nvim/init.lua` だけ。ディレクトリ全体は管理しない |
| `herdr/config.toml` | Herdr のキーと履歴設定 | `~/.config/herdr/config.toml` |
| `karabiner.json` | macOS キー変換 | `~/.config/karabiner/karabiner.json` |
| `local.nix.example` / `private.nix.example` | 個別設定の雛形 | コピーした `.nix` だけが使われる |
| `commit.sh` / `push.sh` | Git の補助 | 前者は全変更を stage + commit、後者は公開先へ push |
| `CLAUDE.md` | エージェントの編集規約 | コメント言語・非公開 URL の禁止など |
| `tests/apply_test.go` | 適用ラッパーの安全性テスト | 一時 Git repo と偽の Nix だけを使う |

この repo だけでは環境は完成しません。Neovim 0.12 の `vim.pack`、Homebrew、sheldon、mise、uv、fzf、fd、rg、zoxide、starship などは別途用意する前提です。`~/.config/shell/env.sh`、`~/.zshrc.local`、各ツールの状態も管理外です。Nix の固定とエディタのプラグイン固定は別問題です。

## 読む順番（初回は約40分、目安）

1. **5分：この地図と上の適用の副作用。** 「Mac 全体か、自分のホームか」を答える。
2. **8分：[Nix の最小モデル](docs/nix.md) と `flake.nix`。** `inputs` → `pkgs` → `modules` → `homeConfigurations.default` を指で追う。`flake.lock` は構造だけ見て、ハッシュを読まない。
3. **5分：`home.nix`。** パッケージ一覧とリンク一覧の二つに分けて読む。`home.stateVersion` は変更しない。
4. **8分：下の alias の完成例。** `shell/aliases.zsh` → `home.nix` → `shell/zshrc` を往復する。まず設定が届く経路を覚える。
5. **7分：`nvim/init.lua` の SECTION 1、2、11。** 日常の設定・操作・検索に限定。次に必要になったら SECTION 6（LSP）、7（整形）、8（補完）、9（構文木）を読む。冒頭の長い Kickstart 説明と全プラグインの精読は後回し。
6. **3分：`karabiner.json` の最初の3ルールと `herdr/config.toml`。** Caps Lock → Control+Option → Herdr の pane 移動を追う。続く Control+hjkl → 矢印との順序が重要。
7. **4分：[検証・適用・復旧](docs/operations.md)。** build と switch の違い、前世代の場所を説明できれば今日は終了。

途中で時間が切れたら4までで止めて構いません。翌日はファイルを閉じて「alias の変更はどこで、誰が読み、どこに置かれる？」「build と switch の違いは？」「lock と stateVersion の違いは？」を各1文で答え、迷った箇所だけ読み直します。

## 完成例：`n` が `nvim` を起動するまで

この例は**すでに実装されています**。まず変更せずに追ってください。

```zsh
# shell/aliases.zsh
alias n='nvim'
```

`home.nix` の `xdg.configFile."shell/aliases.zsh".source = ./shell/aliases.zsh;` が、適用時に `~/.config/shell/aliases.zsh` として配置します。`shell/zshrc` は `home.file.".zshrc"` で配置され、その中の `source ~/.config/shell/aliases.zsh` が alias を定義します。新しい対話 zsh で `alias n` と `command -v nvim` を確認します。前者は設定、後者は実行ファイルの存在の確認です。

小さく練習するなら、自分の作業ブランチで同じファイルに `alias nv='nvim'` を一つ追加します。`zsh -n shell/aliases.zsh` → `git diff -- shell/aliases.zsh` → [運用手順の build](docs/operations.md) の順に進みます。`flake.nix` やパッケージ一覧を同時に変える必要はありません。取り消しは追加した1行だけを戻します。すでに適用した場合は戻した設定を再適用するか、前世代を有効化します。

## なぜ今は大きく分割しないのか

`home.nix` は61行、`flake.nix` も短く、設定を追うためにファイルを増やす利点が小さいためです。1068行の `nvim/init.lua` は長いものの SECTION と `do ... end` でまとまっています。まず読順と機能の見出しを使います。分割は「頻繁に編集する機能が特定できた」「読み込み順と共通の `gh` 関数を説明できた」段階で、Snacks など一機能ずつ行えば十分です。その際は `home.nix` に追加ファイルのリンクが必要です。

学習設計として、完成例を追ってから小変更を試し、翌日に思い出す流れを採用しました。[IES の学習ガイド](https://ies.ed.gov/ncee/wwc/PracticeGuide/1) の例題・想起・分散学習の知見を、この repo に応用した設計判断です。Nix のリポジトリ構成を直接実験した結論ではなく、科学的な最適ファイル数や行数を主張するものではありません。
