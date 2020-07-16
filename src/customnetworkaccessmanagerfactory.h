#ifndef CUSTOMNETWORKACCESSMANAGERFACTORY_H
#define CUSTOMNETWORKACCESSMANAGERFACTORY_H

#include <QNetworkProxy>
#include <QQmlNetworkAccessManagerFactory>

class CustomNetworkAccessManagerFactory : public QQmlNetworkAccessManagerFactory
{
public:
    ~CustomNetworkAccessManagerFactory() override;

    QNetworkAccessManager *create(QObject *parent = nullptr) override;

    static QNetworkProxy proxy;
};

#endif // CUSTOMNETWORKACCESSMANAGERFACTORY_H
