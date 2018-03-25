/* This file is part of Gopherette, the SailfishOS Gopher-space browser.
 * Copyright (C) 2018 - Jérémy Farnaud
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

.pragma library

function isWebURL(s) {
    print("Testing: " + s)
    if (s.substr(0, 4) === 'URL:') return s.substr(4);
    var sl = s.toLowerCase();
    if (sl.substr(0, 7) === "http://" || sl.substr(0, 8) === "https://") return s;
    return false;
}

function repeat(s, n) {
    var r = "";
    for (var i = 0; i < n; ++i) r += s;
    return r;
}

function removeTrailingSlash(s) {
    return s.replace(/\/$/, "");
}
