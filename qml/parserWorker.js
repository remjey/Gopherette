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

Qt.include("utils.js")

var pageType, reflowedTextSize;

var cuteBuf = "", currentCuteType, canAddNewLine;
var rawBuf = "";
var config = {};

var M = {}

WorkerScript.onMessage = function (msg) {
    M[msg.action](msg);
}

M.start = function (msg) {
    pageType = msg.type;
    reflowedTextSize = msg.reflowedTextSize;
    currentCuteType = "";
    cuteBuf = "";
    rawBuf = "<pre>";
    config.rawTextPrefixColor = msg.rawTextPrefixColor;
}

M.end = function (msg) {
    cutebufType("");
    rawBuf += "</pre>"
}

M.text = function (msg) {
    var tt = transform(msg.line, currentCuteType);
    cutebufType(tt.type);
    if (tt.line.match(/^([*+-]|[0-9]+[.)-])/) && canAddNewLine) cuteBuf += "<br>" + hesc(tt.line);
    else cuteBuf += nl() + hesc(tt.line);

    rawBuf +=  (pageType === "0" ? "" : "       ") + hesc(msg.line) + "<br>";
}

M.error = function (msg) {
    cutebufType("err");
    cuteBuf += nl() + '⚠ <b>' + hesc(msg.line) + '</b>';

    rawBuf += nl() + " (ERR) " + hesc(msg.line);
}

M.link = function (msg) {
    var prefix;

    var selectorIsWebURL = msg.type === "h" && !!isWebURL(msg.selector);

    cutebufType("link");
    switch (msg.type) {
    case '1': prefix = '📂'; break;
    case '7': prefix = '🔍'; break;
    case '+': prefix = '⨁'; break; // TODO BACKUP
    case 's': prefix = '🔊'; break;

    case '0':
    case '5':
        prefix = '📄';
        break;

    case 'T':
    case '8':
        prefix = '💻';
        break;

    case '4':
    case '6':
    case '9':
        prefix = '🗋';
        break; // TODO FILES (compression? 🗜)

    case 'g':
    case 'I':
        prefix = '🖼';
        break; // TODO IMAGE

    case 'h':
        if (selectorIsWebURL) prefix = '🌍';
        else prefix = '🖺';
        break;

    default: prefix = '⛔'; type = '?'; break;
    }
    cuteBuf += nl() + prefix + ' <a href="' + msg.ilink + '">' + hesc(msg.name) + '</a>';

    switch (msg.type) {
    case '0': prefix = 'FILE'; break;
    case '1': prefix = ' DIR'; break;
    case '2': prefix = ' CSO'; break;
    case '4': prefix = ' HQX'; break;
    case '5': prefix = ' BIN'; break;
    case '6': prefix = ' UUE'; break;
    case '7': prefix = '  ? '; break;
    case '8': prefix = '3270'; break;
    case '9': prefix = ' BIN'; break;
    case '+': prefix = 'BCKP'; break; // TODO BACKUP
    case 'g':
    case 'I':
        prefix = ' IMG';
        break; // TODO IMAGE
    case 'h':
        if (selectorIsWebURL) prefix = ' WEB';
        else prefix = 'HTML';
        break;
    case 's': prefix = ' SND'; break;
    case 'T': prefix = ' TEL'; break;
    default: prefix = 'UNKN'; break;
    }
    rawBuf += '<font color="' + config.rawTextPrefixColor + '">' + prefix + '</font>  <a href="' + msg.ilink + '">' + hesc(msg.name) + '</a><br>';
}

M.render = function () {
    print(rawBuf);
    WorkerScript.sendMessage({ action: "render", cutebuf: cuteBuf, rawbuf: rawBuf });
    cuteBuf = "";
    rawBuf = "";
}

function hesc(s) {
    return s.replace(/[<>&]/g, function (c) {
        switch (c) {
        case '<': return "&lt;";
        case '>': return "&gt;";
        case '&': return "&amp;";
        }
    });
}

function nl() {
    if (canAddNewLine) {
        if (currentCuteType === "text") return " ";
        return "<br>";
    } else {
        canAddNewLine = true;
        return '';
    }
}

function cutebufType(type) {
    if (type === currentCuteType) return false;

    if (currentCuteType === "ascii-art") {
        cuteBuf += '</pre></font>';
    } else if (currentCuteType === "strong") {
        cuteBuf += "</b></font>"
        if (type !== "ascii-art") cuteBuf += "<br>";
    } else if (currentCuteType === "text" || currentCuteType == "link" || currentCuteType == "err") {
        cuteBuf += "</font>"
        if (type !== "empty" && type !== "ascii-art") cuteBuf += "<br>";
    } else if (currentCuteType === "empty") {
        cuteBuf += "</font>"
    }

    canAddNewLine = false;

    if (type === "ascii-art") {
        cuteBuf += '<font size="1"><pre>';
    } else if (type === "text" || type === "link" || type === "err") {
        cuteBuf += '<font size="' + reflowedTextSize + '">'
    } else if (type === "strong") {
        cuteBuf += '<font size="' + reflowedTextSize + '"><b>'
    } else if (type === "empty") {
        cuteBuf += '<font size="1"><br>'
        if (currentCuteType === "text" || currentCuteType === "link" || currentCuteType === "err") cuteBuf += "<br>";
    }

    currentCuteType = type;
    return true;
}

function transform(s) {
    var trs = s.trim();
    if (trs === "") return { type: "empty", line: "" };
    var strongMatch = trs.match(/^[=+*\[\]_-]+(.{4,}?)[=+*\[\]_-]+$/) // TODO check that the padding char is the same everywhere on the line
    if (strongMatch && !isStringSpecial(strongMatch[1].trim())) return { type: "strong", line: strongMatch[1].trim().replace(/_/g, " ") };
    if (isStringSpecial(trs)) return { type: "ascii-art", line: s };
    if (s.length - trs.length > 8) return { type: "strong", line: trs };
    return { type: "text", line: trs };
}

function isStringSpecial(trs) {
    var spaces = 0;
    var special = 0;
    var non_special = 0;
    for (var i = 0; i < trs.length; ++i) {
        var c = trs[i];
        if (c === " ") {
            ++spaces;
        } else if (isCharSpecial(c)) {
            ++special;
        } else {
            ++non_special;
        }
    }
    return ((spaces + special) / trs.length) > 0.60;
}

function isCharSpecial(c) {
    return "!\"#'()*+,-./:;<=>?@[\\]^_`{|}~08oAMmWwVOx".indexOf(c) != -1 || c.charCodeAt(0) > 127;
}
