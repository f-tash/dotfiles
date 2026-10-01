# この repo で使う Nix だけ

Nix は設定を値として計算する言語でもあり、パッケージを作るツールでもあります。Home Manager はその上で「ユーザー環境」のオプションを統合し、適用プログラムを作ります。この repo では `homeConfigurations.default` がその一式です。

## 実コードを6段階で追う

1. `flake.nix` の **inputs** は材料の入手先。`nixpkgs`（パッケージ定義）、`home-manager`（ホームの管理）、`herdr`（独自パッケージ）です。
2. **flake.lock** は実際に使う各 Git revision と内容ハッシュ。`follows = "nixpkgs"` は依存側も同じ nixpkgs を使う指定。`nix flake update` はこの固定を変更する操作なので、日常の設定編集と分けます。
3. `pkgs = import nixpkgs { ... };` は **aarch64-darwin 向けパッケージ集合**を作ります。overlay で `pkgs.herdr` を加え、非自由ソフトは `cursor-cli` と `orbstack` だけ許可しています。今回この許可範囲は変えていません。
4. `localConfig` は `local.nix` の属性集合を読みます。`{ username = "..."; }` が `extraSpecialArgs` 経由で `home.nix` の引数になります。ファイルなしの公開 flake 評価では `user` にフォールバックしますが、`apply.sh` は誤適用を防ぐためファイルなしを拒否します。
5. `modules = [ ./home.nix ] ++ privateModules;` が設定を統合します。`private.nix` があれば追加。後のファイルが無条件に上書きする仕組みではありません。オプションの型・優先度に従って統合され、衝突はエラーにもなります。
6. `home-manager.lib.homeManagerConfiguration` が **activationPackage** を作ります。評価は設計の計算、build は必要な実体の作成、switch はその世代をホームに反映する操作です。評価や build でもネットワーク取得・store 書き込みはあり得ます。

今回追加した `packages.aarch64-darwin.home-manager` は、同じ input の CLI を `nix run ...#home-manager` で呼ぶための出口です。`homeConfigurations.default` の設定内容は変えていません。

## 読むのに必要な構文

| 実際の表記 | 意味 |
|---|---|
| `{ pkgs, username, ... }: { ... }` | 引数の集合を受け取り、設定の集合を返す関数。`...` は他の引数も許す |
| `{ username = "user"; }` | 属性集合。JSON に似るが値は式になり、各定義末尾に `;` |
| `[ ./home.nix ] ++ privateModules` | リストの連結 |
| `let ... in ...` | 名前を定義し、その名前を使った式を返す |
| `inherit system;` | `system = system;` の省略 |
| `"/Users/${username}"` | 文字列への値の埋め込み |
| `./shell/aliases.zsh` | Nix ファイルからの相対パス。適用先ではなく入力 |
| `xdg.configFile."nvim/init.lua".source` | 名前に `/` を含む設定項目。ホーム内へのリンクを Home Manager が作る |

**`import` と `imports` は別です。** `import ./local.nix` は Nix 言語の組み込み関数で、ファイルの式を評価します。`imports = [ ./other.nix ];` は Home Manager/NixOS の module system が読む設定項目です。この repo の `home.nix` は `imports` を使わず、flake 側の `modules` で集めています。`private.nix.example` の `import "${privateSrc}/home.nix"` は前者です。

## 固定されるもの・されないもの

- `flake.lock`：Nix の入力 revision。今回更新していません。
- `home.stateVersion = "25.11"`：過去の挙動との互換性を選ぶ値。Nix や Home Manager を更新する命令ではありません。バージョンが古く見えるからと上げません。
- `vim.pack.add`：Neovim プラグイン。多くは既定ブランチ、LuaSnip と blink は major の範囲指定。Nix lock はこれらを固定しません。
- Mason / Tree-sitter：LSP、整形ツール、parser を Neovim 側でインストール。generation の rollback と独立しています。
- `private.nix.example` の `fetchGit`：`ref = "main"` のままでは動く参照。再現性が必要なら、その私有ファイル内で `rev` を固定します。

`--impure` は外部状態の参照を許すものです。Nix の安全性検証や秘密保護を強化する指定ではありません。非公開 overlay の互換性のため維持しています。非公開ファイル・参照先の内容は今回取得も監査もしていません。

## Nix 管理の外側

パッケージ一覧に Neovim 本体はありません。shell は複数の外部コマンドと手動の `env.sh` を前提にしています。Neovim 本体、プラグイン、Mason、Homebrew、mise が別々に更新されるため、「lock があるので機械全体が完全に同じ」とは言えません。まず自分の Mac でどこから各コマンドが来るかを `command -v` で確認します。

詳しく必要になったら [Nix 言語の公式入門](https://nix.dev/tutorials/nix-language)、[flake の公式リファレンス](https://nix.dev/manual/nix/2.35/command-ref/new-cli/nix3-flake)、[Home Manager manual](https://nix-community.github.io/home-manager/) を参照してください。この文書の説明は、この repo の構成に絞っています。
