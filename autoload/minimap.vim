function! minimap#ShowMinimap()
python << EOF
import vim

WIDTH = 20

MINIMAP = "vim-minimap"

minimap = None

for b in vim.buffers:
    if b.name.endswith(MINIMAP):
        for w in vim.windows:
            if w.buffer == b:
                minimap = w
                break

# If the minimap window does not yet exist, create it
if not minimap:
    # Save the currently active window to restore it later
    src = vim.current.window

    vim.command(":botright vnew %s" % MINIMAP)
    # make the new buffer 'temporary'
    vim.command(":setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted")
    # make ensure our buffer is uncluttered
    vim.command(":setlocal nonumber norelativenumber nolist")

    # Properly close the minimap when quitting VIM (ie, when minimap is the last remaining window
    vim.command(":autocmd! WinEnter <buffer> if winnr('$') == 1|q|endif")

    vim.command(':autocmd! CursorMoved,CursorMovedI,TextChanged,TextChangedI,BufWinEnter * MinimapUpdate')

    minimap = vim.current.window

    minimap.width = WIDTH

    # fixed size
    vim.command(":set wfw")

    # Restore the active window
    vim.current.window = src

vim.command(":MinimapUpdate")

EOF
endfunction

function! minimap#UpdateMinimap()
python << EOF
# vim-minimap is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# vim-minimap is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with vim-minimap. If not, see < http://www.gnu.org/licenses/ >.
#
# (C) 2014- by Séverin Lemaignan for the VIM integration, <severin@guakamole.org>
# (C) 2014- by Adam Tauber for the Drawille part, <asciimoo@gmail.com>


import vim
import math

"""
START OF DRAWILLE CODE
https://github.com/asciimoo/drawille
"""

from sys import version_info
from collections import defaultdict

IS_PY3 = version_info[0] == 3

if IS_PY3:
    unichr = chr

"""

http://www.alanwood.net/unicode/braille_patterns.html

dots:
   ,___,
   |1 4|
   |2 5|
   |3 6|
   |7 8|
   `````
"""

pixel_map = ((0x01, 0x08),
             (0x02, 0x10),
             (0x04, 0x20),
             (0x40, 0x80))

# braille unicode characters starts at 0x2800
braille_char_offset = 0x2800


def normalize(coord):
    coord_type = type(coord)

    if coord_type == int:
        return coord
    elif coord_type == float:
        return int(round(coord))
    else:
        raise TypeError("Unsupported coordinate type <{0}>".format(type(coord)))


def intdefaultdict():
    return defaultdict(int)


def get_pos(x, y):
    """Convert x, y to cols, rows"""
    return normalize(x) // 2, normalize(y) // 4


class Canvas(object):
    """This class implements the pixel surface."""

    def __init__(self):
        super(Canvas, self).__init__()
        self.clear()
        self.line_ending = "\n"


    def clear(self):
        """Remove all pixels from the :class:`Canvas` object."""
        self.chars = defaultdict(intdefaultdict)


    def set(self, x, y):
        """Set a pixel of the :class:`Canvas` object.

        :param x: x coordinate of the pixel
        :param y: y coordinate of the pixel
        """
        x = normalize(x)
        y = normalize(y)
        col, row = get_pos(x, y)

        if type(self.chars[row][col]) != int:
            return

        self.chars[row][col] |= pixel_map[y % 4][x % 2]


    def unset(self, x, y):
        """Unset a pixel of the :class:`Canvas` object.

        :param x: x coordinate of the pixel
        :param y: y coordinate of the pixel
        """
        x = normalize(x)
        y = normalize(y)
        col, row = get_pos(x, y)

        if type(self.chars[row][col]) == int:
            self.chars[row][col] &= ~pixel_map[y % 4][x % 2]

        if type(self.chars[row][col]) != int or self.chars[row][col] == 0:
            del(self.chars[row][col])

        if not self.chars.get(row):
            del(self.chars[row])


    def toggle(self, x, y):
        """Toggle a pixel of the :class:`Canvas` object.

        :param x: x coordinate of the pixel
        :param y: y coordinate of the pixel
        """
        x = normalize(x)
        y = normalize(y)
        col, row = get_pos(x, y)

        if type(self.chars[row][col]) != int or self.chars[row][col] & pixel_map[y % 4][x % 2]:
            self.unset(x, y)
        else:
            self.set(x, y)


    def set_text(self, x, y, text):
        """Set text to the given coords.

        :param x: x coordinate of the text start position
        :param y: y coordinate of the text start position
        """
        col, row = get_pos(x, y)

        for i,c in enumerate(text):
            self.chars[row][col+i] = c


    def get(self, x, y):
        """Get the state of a pixel. Returns bool.

        :param x: x coordinate of the pixel
        :param y: y coordinate of the pixel
        """
        x = normalize(x)
        y = normalize(y)
        dot_index = pixel_map[y % 4][x % 2]
        col, row = get_pos(x, y)
        char = self.chars.get(row, {}).get(col)

        if not char:
            return False

        if type(char) != int:
            return True

        return bool(char & dot_index)


    def rows(self, min_x=None, min_y=None, max_x=None, max_y=None):
        """Returns a list of the current :class:`Canvas` object lines.

        :param min_x: (optional) minimum x coordinate of the canvas
        :param min_y: (optional) minimum y coordinate of the canvas
        :param max_x: (optional) maximum x coordinate of the canvas
        :param max_y: (optional) maximum y coordinate of the canvas
        """

        if not self.chars.keys():
            return []

        minrow = min_y // 4 if min_y != None else min(self.chars.keys())
        maxrow = (max_y - 1) // 4 if max_y != None else max(self.chars.keys())
        mincol = min_x // 2 if min_x != None else min(min(x.keys()) for x in self.chars.values())
        maxcol = (max_x - 1) // 2 if max_x != None else max(max(x.keys()) for x in self.chars.values())
        ret = []

        for rownum in range(minrow, maxrow+1):
            if not rownum in self.chars:
                ret.append('')
                continue

            maxcol = (max_x - 1) // 2 if max_x != None else max(self.chars[rownum].keys())
            row = []

            for x in  range(mincol, maxcol+1):
                char = self.chars[rownum].get(x)

                if not char:
                    row.append(' ')
                elif type(char) != int:
                    row.append(char)
                else:
                    row.append(unichr(braille_char_offset+char))

            ret.append(''.join(row))

        return ret


    def frame(self, min_x=None, min_y=None, max_x=None, max_y=None):
        """String representation of the current :class:`Canvas` object pixels.

        :param min_x: (optional) minimum x coordinate of the canvas
        :param min_y: (optional) minimum y coordinate of the canvas
        :param max_x: (optional) maximum x coordinate of the canvas
        :param max_y: (optional) maximum y coordinate of the canvas
        """
        ret = self.line_ending.join(self.rows(min_x, min_y, max_x, max_y))

        if IS_PY3:
            return ret

        return ret.encode('utf-8')

"""
END OF DRAWILLE CODE
"""
HORIZ_SCALE = 0.1
WIDTH = 20

MINIMAP = "vim-minimap"

src = vim.current.window
cursor = src.cursor

vim.command("normal! H")
topline = src.cursor[0]
vim.command("normal! L")
bottomline = src.cursor[0]

minimap = None

for b in vim.buffers:
    if b.name.endswith(MINIMAP):
        for w in vim.windows:
            if w.buffer == b:
                minimap = w
                break

def draw(lengths, startline = 0):

    c = Canvas()

    for y, l in enumerate(lengths):
        for x in range(2 * min(int(l * HORIZ_SCALE), WIDTH)):
            c.set(x, y)

    # pad with spaces to ensure uniform block highligthing
    return [line.ljust(WIDTH) for line in c.rows()]


if minimap:

    vim.current.window = minimap

    lengths = []

    for line in range(len(src.buffer)):
        lengths.append(len(src.buffer[line]))


    vim.command(":setlocal modifiable")

    minimap.buffer[:] = draw(lengths)
    # Highlight the current visible zone
    top = topline/4
    bottom = bottomline/4 + 1
    vim.command("match WarningMsg /\%>0v\%<{}v\%>{}l\%<{}l./".format(WIDTH+1, top, bottom))

    # center the highlighted zone
    height = int(vim.eval("winheight(0)"))
    # first, put the cursor at the top of the buffer
    vim.command("normal! gg")
    # then, jump so that the active zone is centered
    if (top + (bottom - top)/2) > height/2:
        jump = min( top + (bottom - top)/2 + height/2, len(minimap.buffer))
        vim.command("normal! %dgg" % jump)

    # prevent any further modification
    vim.command(":setlocal nomodifiable")

    vim.current.window = src
    src.cursor = cursor

EOF
endfunction

function! minimap#CloseMinimap()
python << EOF
import vim

MINIMAP = "vim-minimap"


for b in vim.buffers:
    if b.name.endswith(MINIMAP):
        for w in vim.windows:
            if w.buffer == b:
                src = vim.current.window
                vim.current.window = w
                vim.command(":quit!")
                vim.current.window = src
                break


EOF
endfunction

