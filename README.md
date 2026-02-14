# dotfiles

chezmoiで管理するdotfilesリポジトリ

## セットアップ（新しいマシン）

```bash
# 1. Homebrewをインストール
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. chezmoiをインストール
brew install chezmoi

# 3. dotfilesを適用
chezmoi init --apply https://github.com/f-tash/dotfiles.git
```

## 更新を取り込む（別マシンで変更があった場合）

```bash
chezmoi update
```

## 基本コマンド

```bash
chezmoi managed          # 管理対象ファイルを確認
chezmoi add ~/.config/x  # 新しいファイルを追加
chezmoi diff             # 変更を確認
chezmoi apply            # 変更を適用
chezmoi cd               # chezmoiリポジトリに移動
chezmoi edit ~/.config/x # 管理対象ファイルを編集
```

## 管理対象

| ファイル | 説明 |
|----------|------|
| `.zshrc` / `.zprofile` | シェル設定 |
| `.Brewfile` | Homebrewパッケージ一覧 |
| `.config/shell/` | 共通シェル環境設定 |
| `.config/zellij/` | Zellijターミナルマルチプレクサ設定 |
| `.config/sheldon/` | Sheldonプラグインマネージャ設定 |
| `.config/mise/` | Miseバージョンマネージャ設定 |
| `.config/karabiner/` | Karabiner-Elements設定 |
| `.config/1Password/` | 1Password SSH agent設定 |
| `.config/nvim/` | Neovim設定（LazyVim starterをexternal管理） |
| `.config/nvim-plugins/` | Neovimカスタムプラグイン設定 |

## Homebrew

Brewfileで以下を管理:

**Formula:** chezmoi, neovim, zellij, gh, sheldon, mise, uv, rustup

**Cask:** google-chrome, rectangle, karabiner-elements, 1password-cli*, tailscale*

*`machine_type = "private"` のみ

`chezmoi init` 時に `machine_type`（private/work）を選択。privateでは1Password CLIとTailscaleが追加される。

パッケージ追加時は`.Brewfile`を編集してcommit。

## nvimについて

nvimはLazyVim starterをexternalで取得し、カスタムプラグイン設定のみこのリポジトリで管理。

- `~/.config/nvim/` → LazyVim/starterから自動clone
- `~/.config/nvim-plugins/` → カスタム設定（apply後に`lua/plugins/`へコピー）

## GitHubへのpush

```bash
chezmoi cd
git add .
git commit -m "update dotfiles"
git push
```
