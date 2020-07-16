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

#ifndef GEMINICACHEDREQUESTDATA_H
#define GEMINICACHEDREQUESTDATA_H

#include <QMutex>
#include <QNetworkReply>


class GeminiCachedRequestData : public QNetworkReply
{
public:
    GeminiCachedRequestData(const QNetworkRequest &request, QObject *parent);
    ~GeminiCachedRequestData() override;

    bool open(OpenMode mode) override;
    qint64 bytesAvailable() const override;
    void close() override;

    bool isSequential() const override;
    bool canReadLine() const override;

    static quint64 steal(QByteArray &data);

public slots:
    void abort() override;

protected:
    qint64 readData(char *data, qint64 maxSize) override;
    qint64 writeData(const char *data, qint64 len) override;

private slots:
    void deferredReadyRead();

private:
    quint64 id;
    int pos;
    int size;

    static QMutex cache_mutex;
    static QMap<quint64, QByteArray> cache;
    static quint64 cache_next_id;
};

#endif // GEMINICACHEDREQUESTDATA_H
