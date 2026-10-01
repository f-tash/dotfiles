# レビュー結果と次の作業

2026-10-01、`main` の `a9af92e2ab2e63e7d417fa5845103ff80ba6cf86` を基準に、全17ファイル（1935行）を読んだ結果です。`CLAUDE.md` を確認し、対象 repo 内の `AGENTS.md` / `.agents/skills` はありませんでした。以下は GitHub Issue の下書きに使える優先順の一覧です。Issue / PR の公開・push はしていません。

優先度は **P1 = 次の適用前、P2 = 通常の改善、P3 = 必要になったら**。実際の秘密漏洩を確認したという意味の P0 はありません。

## 修正した問題

| 優先度 | 問題・根拠 | 今回の対応・受け入れ条件 |
|---|---|---|
| P1 | 旧 `apply.sh` は `git add -f` のループ後に trap を設定。2番目の add が失敗すると `local.nix` が stage に残る。ダミー repo と失敗注入で再現 | 実 index を一切更新せず、一時コピーから Nix を呼ぶ。成功・失敗・TERM 後に index がバイト単位で同一 |
| P1 | 旧 trap は元から stage されていた `private.nix` も一律に unstage。Nix が失敗したケースで再現 | 上と同じ。既存 stage の保存も回帰テストに含める |
| P1 | `nix run home-manager/master` は repo の `flake.lock` の Home Manager revision を使う指定ではない。静的確認 | 同じ固定 input の CLI を `packages.aarch64-darwin.home-manager` として公開し、そこから起動。外側・内側で lock 自動更新を拒否 |
| P1 | `local.nix` がなくても `user` という既定値で switch を試せた。事故予防の改善であり、誤適用の実被害は未確認 | local 必須化、switch 前に OS/CPU・ユーザー名・ホームを検査。ビルド専用モードを追加 |
| P2 | `home.nix` / `CLAUDE.md` に lazy.nvim や Noice popupmenu について実コードと異なる説明 | コメントと操作説明を修正。設定値は維持 |
| P2 | `build` が作る `result` を `commit.sh` の `git add -A` が拾い得る | `/result` と `/result-*` を ignore |

旧版の2件は実際の Nix・秘密ファイルを使わずに再現しました。今回の修正は、任意の内容を安全に公開できる仕組みではありません。store への入力コピー、SIGKILL 時の一時ファイル残留、事前に stage されていた私有ファイルは別問題です。特に最後のものは今回あえて勝手に unstage せず、[運用手順](operations.md) で確認・解消するようにしています。

## 未修正の課題：確定事項と推奨を分ける

### P1：新しい Mac で必要になる外部依存を確認する

**静的に確認済みの不足範囲**：`home.packages` に Neovim 本体、sheldon、mise、uv、fzf、fd、rg、zoxide、starship などはありません。一方 `shell/zprofile` は Homebrew と手動の `env.sh`、`shell/zshrc` は複数のコマンドを無条件に実行します。Neovim の設定は 0.12 の API を前提にしています。

**未確認**：tash の Mac で不足しているかは確認していません。既存の Homebrew / mise 環境なら問題が出ない可能性があります。全コマンドを Nix 管理に移す変更はパッケージの重複やバージョン変更を招くため行いませんでした。

**完了条件**：`command -v` と `nvim --version` で各管理元を確認し、README の前提と一致すること。必要なら「必須でなければ command の存在を確認してから初期化する」をツールごとに判断します。

### P2：Lua の整形設定の意図を決める

**設定上の不整合を確認**：`nvim/init.lua` SECTION 6 で `lua_ls` の整形を無効化し、Mason で `stylua` を導入しますが、SECTION 7 の `formatters_by_ft` に `lua = { 'stylua' }` がありません。`format_on_save` の有効ファイル種別も空です。説明コメントから期待する Lua 整形経路が繋がっていません。

**推奨**：Lua の手動整形を使うなら formatter を明示します。保存時整形は好みと差分に影響するため別判断。実際の plugin / LSP を起動していないので実行時のエラーや他設定による補完は未確認です。受け入れ確認は `:ConformInfo` と、小さい Lua ファイルでの手動整形です。

### P2：検索で見えなくなるファイルとキー変換を把握する

**設定で確認済み**：Snacks の `*test*` / `*Test*` はテスト以外の `latest.lua` なども対象になります。LSP picker にも独自フィルタを使い、`git_diff` は除外しています。`T` / 入力中の Alt+t で再表示する設計です。既存の明示的な好みなので変更しませんでした。

**設定経路の衝突**：Karabiner のグローバルな Control+hjkl → 矢印は、Neovim の Control+hjkl → window 移動より前にキーを変えます。Caps Lock/Control+Option の Herdr 移動は、先行する passthrough ルールで別扱いです。実機での key event は未検証です。

**完了条件**：普段使う terminal で「Herdr pane」と「Neovim window」の移動を別々に試し、希望する挙動を記録すること。除外 glob やキーバインドの変更はその後です。

### P2：Nix 以外のバージョンもどこまで固定するか決める

**確認済みの再現性の境界**：プラグインの多くはブランチ指定、Mason と parser は別途取得されます。private の雛形も `fetchGit` の `ref = "main"` のみ。`flake.lock` はこれらを固定しません。

**推奨**：まず動作している Neovim 本体とプラグイン状態を記録し、一括更新を避けます。固定版への置換はアップデート方針として別変更にします。今回 lock、パッケージ一覧、セキュリティ設定を更新していません。

### P3：Herdr JSON の読み方と Neovim の分割

`_herdr_pane_id` はコロン直後に空白がない JSON だけを読むことを、zsh に compact / 空白入りの入力を渡して確認しました。ただし **固定 Herdr `4dd9aa5…` の `src/cli.rs` は `serde_json::to_string` で compact に出力**するため、現行 CLI が壊れているとは判定しません。出力仕様が変わる場合に正式な JSON parser の導入を検討します。

Neovim の物理分割は後回しです。既存 SECTION を読順から辿れるようにしました。分割する際は `gh` ヘルパー、leader 設定と plugin の順序、新しい Lua ファイルの Home Manager リンクを一緒に設計・検証します。

## 変更前後の同等性

本来の動作を変えたのは**適用の入口**だけです。build モード、誤適用の拒否、一時コピー、固定 CLI を追加しています。既存のパッケージ、キー、shell、Neovim、Herdr、Karabiner の設定値は変更していません。`home.nix` はコメントのみ変更です。

Nix 2.20.6 で、同じ lock と同じ入力を与えた前後の `homeConfigurations.default.activationPackage.drvPath` が、次の3ケースで完全一致しました。

| ケース | 前後で同一だった derivation |
|---|---|
| 公開設定のみ（local/private なし） | `/nix/store/qqan83j33zlnqlysi8aywyias9v53mf8-home-manager-generation.drv` |
| ダミー local（username = review-test） | `/nix/store/c9vcjvcqnx4cb5xi8g2a41p5fkpz3ici-home-manager-generation.drv` |
| 同 local + ダミー private module の環境変数 | `/nix/store/2wz99as1vj9kfs3iqzqgpgyjrxvny52j-home-manager-generation.drv` |

これは **ビルドの設計が同じ**という強い確認であり、Darwin の実ビルド成功や端末操作の実機確認ではありません。非公開の実 module は試していません。private の絶対パス import など任意の独自実装を保証するものでもありません。

## 実施したテストと限界

環境：Linux x86_64、Git、zsh 5.9、Go 1.26.2、ShellCheck 0.11.0、Lua 5.3.6 (`texluac`)、Nix 2.20.6。一時領域に配置したツールと専用 Nix store を使用し、ユーザーの dotfiles は適用していません。

| 検査 | 結果 | 何を保証しないか |
|---|---|---|
| 全4 Nix ファイルの `nix-instantiate --parse` | PASS | module の実行結果 |
| `nix flake check --all-systems --no-build --no-update-lock-file` | PASS、追加 CLI derivation も評価 | `homeConfigurations` は独自出力なのでこのコマンドだけでは不十分 |
| 上記3ケースの activationPackage 評価と drvPath 比較 | 全一致 | Darwin でのビルド・適用 |
| `sh -n`、ShellCheck（3 sh scripts） | PASS | 実機の PATH、外部コマンド |
| `zsh -n`（shell 内の4ファイル） | PASS | 起動時に必要な外部環境 |
| `texluac -p nvim/init.lua` | PASS | LuaJIT/Neovim API や plugin の実行時互換性 |
| `jq -e`（Karabiner / lock JSON） | PASS | Karabiner の実入力動作 |
| Nix `builtins.fromTOML`（Herdr） | PASS | Herdr の実 CLI による診断 |
| `GO111MODULE=off go test -v ./tests` | 14ケース PASS | Nix と OS 判定はテスト用コマンドに差し替え。実際の switch は実行しない |
| 旧 apply の故障再現 | stage 残留・既存 stage 破壊の2件を再現 | 実際の秘密漏洩の有無 |
| `git diff --check` | PASS | 上記以外の意味的な問題 |

Go テストは、成功・引数なし switch・Nix 失敗・TERM・既存私有 stage・private なし・local なし・ユーザー/ホーム不一致・Linux・不正引数・追跡ファイル不足を含みます。空白を含むパス、作業ツリーと stage の内容が異なる状態、新規 stage、未追跡ファイル除外も確認します。

未実施：Apple Silicon 上の実ビルドと BSD tar を含む実行、activation / rollback、GUI、Neovim headless の plugin 起動、Herdr 実行ファイルでの `config check`、実際の私有 overlay。Nix portable の仮想化起動は環境の ptrace 制約で失敗しましたが、同梱 static Nix と `/tmp` 配下の local store を使って評価検査を完了しています。

## 明日の最小確認

1. README の地図と読む順を確認する。
2. P1 の外部依存、現在の世代、バックアップ、`local.nix` を確認する。
3. Mac 上で `go test` と `./apply.sh build`。エラーがあれば適用せず、その箇所だけ調べる。
4. 意図したタイミングでのみ `switch`。新しい terminal で確認し、旧 terminal と前世代は残す。

依存更新、プラグイン一括更新、ファイル大分割をこの確認に混ぜないことで、問題が出たときの原因候補を少なくします。

## 配布前の再レビュー

適用ラッパーの失敗経路と、テスト自体が誤って成功しないかを別の観点で再確認しました。実装の追加変更は不要でしたが、テスト内の shell 検査を独立したコマンドへ変更し、`set -e` と `&&` の組合せによる検査漏れを防ぎました。成功ケースが実際に検証済みの Nix 呼び出しへ到達したことと、TERM の終了コード143も確認しています。14ケースを再実行して成功しました。

操作ガイドは、`git check-ignore` がファイル名を表示すること、`sh -n` はスクリプトごとに実行する必要があることを訂正しました。3本それぞれの構文検査、ShellCheck、差分の空白検査も成功しています。実行設定の変更はなく、既存のNix同等性の確認範囲と実機未検証の制約は変わりません。
