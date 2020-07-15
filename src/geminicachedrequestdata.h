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
