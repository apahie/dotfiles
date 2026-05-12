#!/usr/bin/env sh
# [一時的なデバッグ仕込み] hook 子プロセスの実行環境とベル経路を記録する
# 原因確定後はインラインに戻して本ファイルは削除する
set +e
LABEL="${1:-unknown}"
LOG="$HOME/.claude/logs/hook-bell.log"
mkdir -p "$(dirname "$LOG")"

{
  echo "=== $(date '+%Y-%m-%d %H:%M:%S') label=$LABEL pid=$$ ppid=$PPID ==="
  echo "[env]"
  echo "  TMUX=$TMUX"
  echo "  TERM=$TERM"
  echo "  SHELL=$SHELL"
  echo "  PATH=$PATH"
  echo "[fd]"
  echo "  tty = $(tty 2>&1)"
  echo "  fd0 = $(readlink /proc/self/fd/0 2>/dev/null)"
  echo "  fd1 = $(readlink /proc/self/fd/1 2>/dev/null)"
  echo "  fd2 = $(readlink /proc/self/fd/2 2>/dev/null)"
  echo "[tmux]"
  echo "  which tmux = $(command -v tmux 2>&1)"
  T_OUT=$(tmux display-message -p '#{client_tty}' 2>&1)
  T_RC=$?
  echo "  display-message rc=$T_RC out='$T_OUT'"
  echo "[bell attempts]"

  ERR=$(mktemp 2>/dev/null || echo "/tmp/bell-e1.$$")
  if printf '\a' >/dev/tty 2>"$ERR"; then
    echo "  /dev/tty : OK"
  else
    echo "  /dev/tty : FAIL rc=$?"
  fi
  [ -s "$ERR" ] && sed 's/^/    err: /' "$ERR"
  rm -f "$ERR"

  if [ "$T_RC" = 0 ] && [ -n "$T_OUT" ] && [ "${T_OUT#/}" != "$T_OUT" ]; then
    ERR=$(mktemp 2>/dev/null || echo "/tmp/bell-e2.$$")
    if printf '\a' >"$T_OUT" 2>"$ERR"; then
      echo "  $T_OUT : OK"
    else
      echo "  $T_OUT : FAIL rc=$?"
    fi
    [ -s "$ERR" ] && sed 's/^/    err: /' "$ERR"
    rm -f "$ERR"
  else
    echo "  tmux client_tty : SKIP (rc=$T_RC out='$T_OUT')"
  fi
} >>"$LOG" 2>&1

exit 0
