
if exists('loaded_minimap')
    finish
endif

let loaded_minimap = 1

command! MinimapToggle call minimap#ToggleMinimap()
command! Minimap call minimap#ShowMinimap()
command! MinimapClose call minimap#CloseMinimap()
command! MinimapUpdate call minimap#UpdateMinimap()

map <Leader>mm :Minimap<CR>
map <Leader>mu :MinimapUpdate<CR>
map <Leader>mc :MinimapClose<CR>
