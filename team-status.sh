#!/bin/bash
for i in 1 2 3 4 5; do
  echo "=== Pane $i ==="
  tmux capture-pane -t team:0.$i -p | tail -3
  echo ""
done
