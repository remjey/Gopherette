#include "customnetworkaccessmanager.h"
#include "customnetworkaccessmanagerfactory.h"

QNetworkProxy CustomNetworkAccessManagerFactory::proxy;

CustomNetworkAccessManagerFactory::~CustomNetworkAccessManagerFactory()
{

}

QNetworkAccessManager *CustomNetworkAccessManagerFactory::create(QObject *parent)
{
    CustomNetworkAccessManager *r = new CustomNetworkAccessManager(parent);
    r->setProxy(proxy);
    return r;
}
