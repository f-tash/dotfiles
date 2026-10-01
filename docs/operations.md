# 検証・適用・復旧

対象は **Apple Silicon macOS、ログイン中の一般ユーザー**です。`sudo ./apply.sh` は使いません。今回のレビューは Linux 上で評価と隔離テストまで行いました。Mac の実ホーム、Karabiner、セキュリティ設定には適用していません。

## 1. 適用前に確認する

既存のターミナルは閉じずに残します。`git status --short` と `git diff` を読み、別の作業が混ざっていないかを確認します。`commit.sh` は `git add -A` を行うので、差分確認の代わりにはなりません。`push.sh` は公開操作です。

```sh
uname -sm
id -un
command -v nix git tar nvim
nvim --version
command -v sheldon mise uv fzf fd rg zoxide starship
```

Neovim の初回起動はプラグインやツールを取得し得ます。バージョン確認は `--version`、構文だけの検査は後述の `-u NONE` で行います。`~/.config/shell/env.sh`、Homebrew、shell に必要な外部ツールの有無は個別に確認してください。この repo はそれらを全て導入する bootstrap ではありません。

`local.nix` がまだない場合だけ `cp local.nix.example local.nix` し、`username` を `id -un` の結果に合わせます。`private.nix` は必要な人だけ雛形をコピーし、内容を自分でレビューします。公開 repo に私有 URL を書きません。

**`local.nix` / `private.nix` を `git add -f` しないでください。** `.gitignore` は既に追跡されたファイルには効きません。`git ls-files` が何も表示せず、`git check-ignore` が両方のファイル名を表示することを確認します。

```sh
git ls-files -- local.nix private.nix
git check-ignore local.nix private.nix
```

既に誤って stage しただけなら、内容を確認した上で `git restore --staged -- local.nix private.nix` で stage から外します。過去に commit/push した秘密はこの操作では消えません。

## 2. バックアップと戻り先を用意する

既存の Home Manager が使えるなら `home-manager generations` を実行し、現在の世代番号と `/nix/store/...-home-manager-generation` の絶対パスを手元に保存します。直前の動作する Git commit も `git rev-parse HEAD` で記録します。

初回導入や既存の手編集ファイルがある場合は、最低限以下を退避します。設定内容をターミナルに出さず、現在の内容を所有者だけ読めるディレクトリにコピーする例です。既存バックアップを再利用せず、新規作成します。

```sh
backup=$(mktemp -d "$HOME/dotfiles-backup.XXXXXXXX")
for rel in .zprofile .zshrc .config/shell/aliases.zsh .config/shell/herdr.zsh \
  .config/nvim/init.lua .config/herdr/config.toml .config/karabiner/karabiner.json; do
  if [ -e "$HOME/$rel" ]; then
    mkdir -p "$backup/$(dirname "$rel")"
    cp -pL "$HOME/$rel" "$backup/$rel"
  fi
done
printf 'Backup directory: %s\n' "$backup"
```

これはリンク先の**内容**のバックアップです。元の symlink 構造や任意のアプリ状態まで復元するものではありません。既存ファイルとの衝突が出た場合は内容と管理元を調べてから退避し、一括削除や強制上書きで回避しません。

## 3. 適用しない検証

```sh
for f in apply.sh commit.sh push.sh; do
  sh -n "$f" || break
done
for f in shell/zprofile shell/zshrc shell/aliases.zsh shell/herdr.zsh; do
  zsh -n "$f" || break
done
shellcheck apply.sh commit.sh push.sh
jq -e . karabiner.json >/dev/null
jq -e . flake.lock >/dev/null
GO111MODULE=off go test -v ./tests
nix flake check --all-systems --no-build --no-update-lock-file
```

ShellCheck は zsh をサポートしないので zsh ファイルには使いません。Go はテスト用で、適用自体には不要です。Lua 構文だけなら、Lua コンパイラがある環境では `luac -p nvim/init.lua`、Neovim がある Mac では以下です。これは `init.lua` を実行しません。

```sh
nvim --headless -u NONE -i NONE --noplugin \
  -c "lua assert(loadfile('nvim/init.lua'))" -c qa
```

Nix の Git flake は新しい未追跡ファイルを見ません。公開してよい新規ファイルだけ、ファイル名を指定して `git add` します。ローカル設定は追加しません。

```sh
./apply.sh build
```

このコマンドは、追跡対象の**作業ツリーの内容**とローカル設定の一時コピーを使います。既存の stage を変更せず、stage していない編集も含みます。無関係な未追跡ファイルや `.git` はコピーしません。ステージ済みの削除などがあると、コピー失敗や評価エラーになることがあります。Nix の評価・ビルドに成功すると `result` ができ、まだホーム設定は有効になりません。

`nix flake check` だけでは独自の `homeConfigurations` の全内容を検査しきれません。**実際の activationPackage を作る `apply.sh build` が必要**です。`result/activate` は適用プログラムなので、この段階では実行しません。Nix の取得・ビルドや、任意の私有 module が実行するコードまで完全な無副作用にするものではありません。

Herdr の実行ファイルが使える Mac では、`HERDR_CONFIG_PATH="$PWD/herdr/config.toml" herdr config check` で repo のファイルを指定して検査できます。固定された Herdr のソースでこの環境変数を確認しています。単に `herdr config check` とすると通常の設定先を検査します。今回、実行ファイルによる検査は未実施です。

## 4. 意図して反映する

ここからはホームを変更する操作です。ビルド後にファイルを変えた場合はもう一度 build と差分確認を行います。`switch` はその時点の作業ツリーを再ビルドするため、以前の `result` をそのまま適用する保証ではありません。

```sh
./apply.sh switch
```

引数なしの `./apply.sh` も同じです。OS/CPU、設定されたユーザー名とホームが現在のユーザーに一致しなければ停止します。`local.nix` 不在や lock の自動更新が必要な場合も止まります。旧版のように実際の Git index に私有ファイルを登録しません。

新しいターミナルで `alias n` と `command -v nvim` を確認し、Neovim の検索・補完、Herdr の移動、Karabiner の入力を一つずつ確認します。元のターミナルは確認が終わるまで残します。再読み込みのために `.zshrc` を何度も source するとフックが重複する場合があるため、新しい shell で試します。

## 5. 戻す

- **まだ適用していない**：自分が加えた差分だけを戻します。必要がなければ `result` の symlink を削除できます。他人や別作業の変更を一括で破棄しません。
- **Home Manager の直前の世代へ戻す**：この repo の固定 Home Manager CLI では `home-manager switch --rollback` が利用できます。実行前に `home-manager generations` で戻り先を確認してください。コマンドが起動できない場合は、先に記録した動作する世代の絶対パスにある `activate` を直接実行する復旧手段があります。
- **新しい設定で直す**：問題の変更だけを Git 上で戻し、再度 `build` → `switch`。新規ターミナルで確認します。
- **初回導入で前世代がない**：動作した generation がないので rollback に頼れません。管理対象の symlink を一つずつ確認して退避し、バックアップした内容を戻します。既存のシェルを残しておく理由です。

rollback は万能ではありません。手動で動かした shell コマンド、プラグイン更新、Mason、アプリ内データ、private module の任意の activation 副作用は戻らないことがあります。初回に新しく作られたものの完全除去も保証しません。古い世代を削除・GC する前に、安定動作を確かめます。

## 一時コピーの限界

一時ディレクトリは所有者専用で作り、通常終了・エラー・HUP/INT/TERM で削除します。SIGKILL や電源断では削除できません。残った `dotfiles.*` を調べる際も中身をログへ貼らないでください。入力ファイルは Nix store に取り込まれ得ます。一時コピーを消しても store からの削除や機密性は保証されません。これは Git index の事故防止であり、秘密情報管理機構ではありません。
