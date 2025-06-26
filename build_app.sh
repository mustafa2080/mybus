#!/bin/bash
cd /home/safy/Downloads/mybus-main
unset GIT_DIR
unset GIT_WORK_TREE
export FLUTTER_GIT_URL=""
flutter build apk --release --no-tree-shake-icons
