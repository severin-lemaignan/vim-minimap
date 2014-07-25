A code minimap for Vim
======================

The Sublime text-editor can display an useful overview of the code as a
*minimap* sidebar.

We can implement the same thing in Vim, relying on the [Drawille
library](https://github.com/asciimoo/drawille) to 'draw' in text mode.

![Code minimap in Vim](minimap.png)

**Attention**: this extension is not yet ready for general use! It simply
displays the map when calling `Minimap`, but does not do anything useful
yet, like live update or synchronizing scrolling.

Installation
------------

With [vundle](https://github.com/gmarik/Vundle.vim), simply add: `Bundle
'severin-lemaignan/vim-minimap'` to your `.vimrc` and run `BundleInstall` from
vim.

