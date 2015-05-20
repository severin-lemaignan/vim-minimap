" vim-minimap is free software: you can redistribute it and/or modify
" it under the terms of the GNU Affero General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" vim-minimap is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU Affero General Public License for more details.
"
" You should have received a copy of the GNU Affero General Public License
" along with vim-minimap. If not, see < http://www.gnu.org/licenses/ >.
"
" (C) 2014- by Séverin Lemaignan for the VIM integration, <severin@guakamole.org>
" (C) 2014- by Adam Tauber for the Drawille part, <asciimoo@gmail.com>

if has('python')
    " By default Highlight the current screen as a visual selection.
    if !exists('g:minimap_highlight')
        let g:minimap_highlight = 'Visual'
    endif

    let python_module = fnameescape(globpath(&runtimepath, 'autoload/minimap.py'))
    exe 'pyfile ' . python_module
end

function! minimap#ShowMinimap()
    python showminimap()
endfunction

function! minimap#UpdateMinimap()
    python updateminimap()
endfunction

function! minimap#CloseMinimap()
    python closeminimap()
endfunction

function! minimap#ToggleMinimap()
    python toggleminimap()
endfunction

