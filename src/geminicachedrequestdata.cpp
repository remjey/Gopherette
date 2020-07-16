/* This file is part of Gopherette, the SailfishOS Gopher-space browser.
 * Copyright (C) 2020 - Jérémy Farnaud
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

#include "geminicachedrequestdata.h"

#include <QTimer>

QMutex GeminiCachedRequestData::cache_mutex;

QMap<quint64, QByteArray> GeminiCachedRequestData::cache;

quint64 GeminiCachedRequestData::cache_next_id = 1;

GeminiCachedRequestData::GeminiCachedRequestData(const QNetworkRequest &request, QObject *parent)
    : QNetworkReply(parent)
{
    id = request.url().path().mid(1).toULongLong();
    pos = 0;
}

GeminiCachedRequestData::~GeminiCachedRequestData()
{
    if (id != 0) {
        QMutexLocker locker(&cache_mutex);
        cache.erase(cache.find(id));
    }
}

bool GeminiCachedRequestData::open(QIODevice::OpenMode mode)
{
    if (!QIODevice::open(mode)) return false;
    QMutexLocker locker(&cache_mutex);
    bool r = cache.find(id) != cache.end();
    if (r) {
        size = cache[id].size();
        QTimer::singleShot(0, this, &GeminiCachedRequestData::deferredReadyRead);
    }
    return r;
}

qint64 GeminiCachedRequestData::bytesAvailable() const
{
    if (id == 0) return 0;
    QMutexLocker locker(&cache_mutex);
    return QNetworkReply::bytesAvailable() + size - pos;
}

void GeminiCachedRequestData::close()
{
    QIODevice::close();
}

bool GeminiCachedRequestData::isSequential() const
{
    return true;
}

bool GeminiCachedRequestData::canReadLine() const
{
    return false;
}

quint64 GeminiCachedRequestData::steal(QByteArray &data)
{
    QMutexLocker locker(&cache_mutex);
    cache[cache_next_id] = std::move(data);
    return cache_next_id++;
}

void GeminiCachedRequestData::abort()
{
    close();
}

qint64 GeminiCachedRequestData::readData(char *data, qint64 maxSize)
{
    if (id == 0) return -1;
    QMutexLocker locker(&cache_mutex);
    auto &buf = cache[id];
    int len = std::min(static_cast<int>(maxSize), buf.length() - pos);
    if (len <= 0) return 0;
    memcpy(data, buf.data() + pos, static_cast<size_t>(len));
    pos += len;

    return len;
}

qint64 GeminiCachedRequestData::writeData(const char *, qint64)
{
    return -1;
}

void GeminiCachedRequestData::deferredReadyRead()
{
    downloadProgress(size, -1);
    readyRead();
    finished();
}
