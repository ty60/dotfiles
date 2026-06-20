# CLAUDE.md — dotfiles リポジトリガイド

## 概要

個人の dotfiles リポジトリ。`install.sh` がシンボリックリンクを `$HOME` 以下に展開する。再実行しても安全 (冪等)。

## ディレクトリ構成

| パス | 用途 | リンク先 |
|------|------|----------|
| `nvim/` | Neovim 設定 | `~/.config/nvim` |
| `ghostty/config` | Ghostty 設定 | `~/.config/ghostty/config` |
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

## install.sh の仕組み

`LINKS` 配列で「リポジトリ内相対パス:リンク先絶対パス」を一元管理している。

```bash
LINKS=(
  "shell/bashrc:$HOME/.bashrc"
  # ... 他のエントリ
)
```

`ln -sfn` でリンクを張るため、既存のリンクや再実行でも問題ない。

**設定ファイルを追加・移動した場合は `LINKS` 配列も必ず更新すること。**

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
