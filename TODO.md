# TODO

## 検討・調査

- [x] sourcegraph, 学習を促す plugin の削除
- [ ] stop hook で report を残すようにしているが、`/clear` で有効か確認
- [x] tmux の表示がディレクトリ名 (branch-name) だが、ディレクトリ名は worktree を切った元ディレクトリにできないか
- [ ] ide で `C-z` で claude を抜けると、Neovim の pane が削除され worktree も削除される問題
- [x] claude コマンドを `cc` に割り当てたが、`cc` というコマンドが他に存在しないか確認
  - C コンパイラ (`/usr/bin/cc`) と衝突するため abbr 削除
