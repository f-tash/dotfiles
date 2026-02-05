#!/bin/bash
# Copy custom nvim plugins after LazyVim starter is cloned
mkdir -p ~/.config/nvim/lua/plugins
cp ~/.config/nvim-plugins/* ~/.config/nvim/lua/plugins/
