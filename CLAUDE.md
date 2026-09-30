# CLAUDE.md — dotfiles リポジトリガイド

## 概要

個人の dotfiles リポジトリ。`install.sh` がシンボリックリンクを `$HOME` 以下に展開する。再実行しても安全 (冪等)。

## ディレクトリ構成

| パス | 用途 | リンク先 |
|------|------|----------|
| `nvim/` | Neovim 設定 | `~/.config/nvim` |
| `ghostty/config` | Ghostty 設定 | `~/.config/ghostty/config` |
| `hammerspoon/init.lua` | Hammerspoon 設定 (アプリ切り替えホットキー) | `~/.hammerspoon/` |
| `brew/Brewfile` | Homebrew でインストール済みのパッケージ一覧 (Pro) | `~/.Brewfile` |
| `brew/Brewfile.neo` | Neo 用の最小パッケージ一覧 | `~/.Brewfile` (`--neo` 時) |
| `shell/bashrc` | Bash 設定 | `~/.bashrc` |
| `shell/bash_profile` | Bash ログイン設定 | `~/.bash_profile` |
| `shell/zshrc` | Zsh 設定 | `~/.zshrc` |
| `shell/profile` | POSIX sh 設定 | `~/.profile` |
| `shell/inputrc` | Readline 設定 | `~/.inputrc` |
| `shell/prompt.sh` | 最小プロンプト定義 (bashrc から source) | — |
| `tmux/tmux.conf` | tmux 設定 | `~/.tmux.conf` |
| `tmux/pane-jump.sh` | tmux ペイン移動ヘルパー | — |
| `claude/settings.json` | Claude Code 設定 (通知フック等) | `~/.claude/settings.json` |
| `claude/scripts/` | 通知スクリプト群 (notify.sh, ccn-notify 等) | `~/.claude/scripts/` |
| `logi/logi-fix.sh` | Logi Options+ がスプラッシュで固まったときの復旧スクリプト | — |

## install.sh の仕組み

`*_LINKS` 配列で「リポジトリ内相対パス:リンク先絶対パス」を一元管理している。

```bash
COMMON_LINKS=(
  "shell/bashrc:$HOME/.bashrc"
  # ... 他のエントリ
)
```

`ln -sfn` でリンクを張るため、既存のリンクや再実行でも問題ない。

### マシン別プロファイル

| コマンド | 対象 | 張るリンク |
|----------|------|------------|
| `./install.sh` | MacBook Pro (開発機) | `COMMON_LINKS` + `FULL_LINKS` |
| `./install.sh --neo` | MacBook Neo (Pro に SSH する端末) | `COMMON_LINKS` + `NEO_LINKS` |

- `COMMON_LINKS`: シェル・Ghostty・Hammerspoon など、手元の操作に関わるもの
- `FULL_LINKS`: tmux・nvim・Claude Code・herdr など、開発機の上で動かすもの
- シェル設定は両方で共用するため、Pro にしかないファイルを読み込むときは `[ -f ... ] &&` で存在を確認すること
- Hammerspoon のブラウザは、Chrome がインストールされていれば Chrome、なければ Safari を開く

**設定ファイルを追加・移動した場合は、該当する `*_LINKS` 配列も必ず更新すること。**

## Homebrew パッケージ管理

`brew/Brewfile` が `requirements.txt` 相当。`~/.Brewfile` にリンクされているため
`--global` を付ければどのディレクトリからでも実行できる。

```bash
brew bundle install --global   # Brewfile の内容を再現する (新しいマシンのセットアップ)
brew bundle check --global     # 差分を確認する
brew bundle dump --global --force  # 現在の環境を Brewfile に書き出す (更新時)
brew bundle cleanup --global   # Brewfile に無いものを削除する (--force で実行)
```

**新しくパッケージを入れたら `brew bundle dump --global --force` で Brewfile を更新すること。**

`brew bundle check` は未インストールのものだけでなく**更新があるものも報告する**ため、
差分が出ていても壊れているとは限らない。

組織固有の tap など公開したくないものは `brew/Brewfile.local` に書く (gitignore 済み)。
こちらは明示的にファイル指定して実行する:

```bash
brew bundle install --file=~/dotfiles/brew/Brewfile.local
```

## 補足事項

- `ccn-notify` はコンパイル済みバイナリ。ソースは `claude/scripts/ccn-notify.swift` だが自動ビルドはしない。gitignore 済み。
- `settings.local.json` はローカル専用の秘密/環境固有設定用。gitignore 済みのため、機密情報はここに記述する。

---

> [!CAUTION]
> **このリポジトリは GitHub のパブリックリポジトリで管理されている。**
>
> 以下の情報を絶対にコミットしないこと:
> - API キー・トークン・パスワード
> - メールアドレス・氏名等の個人情報
> - IP アドレス・ホスト名等のネットワーク情報
>
> 新しいファイルを追加・編集する際は、秘密情報が含まれていないか必ず確認すること。
> ローカル専用設定は `settings.local.json` 等の gitignore 済みファイルに記述すること。
