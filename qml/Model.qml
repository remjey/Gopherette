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

pragma Singleton
import QtQuick 2.0
import QtQuick.LocalStorage 2.0
import Sailfish.Silica 1.0

QtObject {

    property var _db;

    property int allowedOrientations: Orientation.All
    property var bookmarksPage

    property ListModel bookmarks: ListModel {}
    property ListModel history: ListModel {}
    property var historyPages: ({})

    function _findBookmarkIndex(id) {
        for (var i = 0; i < bookmarks.count; ++i) {
            if (bookmarks.get(i).id === id) {
                return i;
            }
        }
        return false;
    }

    function _setBookmark(idx, id, name, host, port, type, selector) {
        var r = { id: id, name: name, host: host, port: port, type: type, selector: selector };
        if (idx !== false) {
            bookmarks.set(idx, r);
        } else {
            bookmarks.append(r);
        }
    }

    function setBookmark(id, name, host, port, type, selector) {
        if (id !== false) {
            _db.transaction(function (tx) {
                tx.executeSql("update bookmarks set name = ?, host = ?, port = ?, type = ?, selector = ? where id = ?",
                              [ name, host, port, type, selector, id ]);
            });
            _setBookmark(_findBookmarkIndex(id), id, name, host, port, type, selector);
        } else {
            var rid = false;
            _db.transaction(function (tx) {
                var r = tx.executeSql("insert into bookmarks (name, host, port, type, selector) values (?, ?, ?, ?, ?)",
                                      [ name, host, port, type, selector ]);
                rid = r.insertId;
            });
            _setBookmark(false, id, name, host, port, type, selector);
        }
    }

    function delBookmark(id) {
        _db.transaction(function (tx) {
            tx.executeSql("delete from bookmarks where id = ?", [ id ]);
        });
        var idx = _findBookmarkIndex(id);
        if (idx !== false) bookmarks.remove(idx);
    }

    function getConfig(k, def) {
        if (_configIndex.hasOwnProperty(k)) return config.get(_configIndex[k]).v;
        return def;
    }

    function setConfig(k, v) {
        config.setProperty(_configIndex[k], "v", v)
        _db.transaction(function (tx) {
            tx.executeSql("update settings set v = ? where k = ?", [ v, k ]);
        });
    }

    property ListModel config: ListModel { }
    property var _configIndex: ({});


    property string cfgPortraitReflow: "portrait.reflow"
    property string cfgReflowFontSmaller: "reflow.font.smaller"
    property string cfgPortraitRawFontSize: "portrait.raw.font.size"
    property string cfgLandscapeRawFontSize: "landscape.raw.font.size"
    property string cfgOpenBinaryAsText: "open.binary.as.text"
    property string cfgHistoryGoBackIfSelectorExists: "history.go.back.if.selector.exists"
    property string cfgRawLineHeight: "raw.line.height"

    Component.onCompleted: {
        _db = LocalStorage.openDatabaseSync("Gopherette", "", "Gopherette Settings", 100000);

        var dbVersions = [
            { from: "", to: "0.1", upgrade: function (tx) {
                tx.executeSql("create table bookmarks (id integer primary key autoincrement, name text not null, host text not null, port integer not null default 70, type text not null default '1', selector text not null default '')");
                tx.executeSql("insert into bookmarks (name, host, port) values ('Floodgap', 'gopher.floodgap.com', 70)");
            }},
            { from: "0.1", to: "0.2", upgrade: function (tx) {
                tx.executeSql("create table settings (k text primary key, v text)");
                tx.executeSql("insert into settings (k, v) values (?, ?)", [ "font.size.landscape", Theme.fontSizeSmall ]);
                tx.executeSql("insert into settings (k, v) values (?, ?)", [ "font.size.portrait", Theme.fontSizeSmall ]);
            }},
            { from: "0.2", to: "0.3", upgrade: function (tx) {
                tx.executeSql("delete from settings");
                tx.executeSql("alter table settings add ord real not null default 0");
                tx.executeSql("insert into settings (k, v, ord) values (?, ?, 1)", [ cfgPortraitReflow, "true" ]);
                tx.executeSql("insert into settings (k, v, ord) values (?, ?, 2)", [ cfgReflowFontSmaller, "false" ]);
                tx.executeSql("insert into settings (k, v, ord) values (?, ?, 3)", [ cfgPortraitRawFontSize, "11" ]);
                tx.executeSql("insert into settings (k, v, ord) values (?, ?, 4)", [ cfgLandscapeRawFontSize, "19" ]);
                tx.executeSql("insert into settings (k, v, ord) values (?, ?, 5)", [ cfgOpenBinaryAsText, "false" ]);
                tx.executeSql("insert into settings (k, v, ord) values (?, ?, 6)", [ cfgHistoryGoBackIfSelectorExists, "false" ]);
            }},
            { from: "0.3", to: "0.4", upgrade: function (tx) {
                tx.executeSql("insert into settings (k, v, ord) values (?, ?, 7)", [ cfgRawLineHeight, "1.20" ]);
            }},
        ]

        var latestDbVersion = dbVersions[dbVersions.length - 1].to;
        if (_db.version !== dbVersions[dbVersions.length]) {
            var currentDbVersion = _db.version;
            _db.changeVersion(currentDbVersion, latestDbVersion, function (tx) {
                dbVersions.every(function (v) {
                    if (currentDbVersion === v.from) {
                        v.upgrade(tx);
                        currentDbVersion = v.to;
                    }
                    return true;
                });
            });
        }

        ///////

        _db.transaction(function (tx) {
            var i, item;

            var r = tx.executeSql("select * from bookmarks");
            for (i = 0; i < r.rows.length; i++) {
                bookmarks.append(r.rows.item(i));
            }

            r = tx.executeSql("select * from settings order by ord");
            for (i = 0; i < r.rows.length; i++) {
                item = r.rows.item(i);
                _configIndex[item.k] = config.count;
                config.append(item);
            }
        });
    }
}
