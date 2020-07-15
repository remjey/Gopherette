# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-gopherette

CONFIG += sailfishapp

SOURCES += src/harbour-gopherette.cpp \
    src/customreply.cpp \
    src/customnetworkaccessmanager.cpp \
    src/geminicachedrequestdata.cpp \
    src/requester.cpp

OTHER_FILES += qml/harbour-gopherette.qml \
    qml/cover/CoverPage.qml \
    rpm/harbour-gopherette.spec \
    rpm/harbour-gopherette.yaml \
    translations/*.ts \
    harbour-gopherette.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172 256x256

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-gopherette-de.ts

HEADERS += \
    src/customreply.h \
    src/geminicachedrequestdata.h \
    src/harbour-gopherette.h \
    src/customnetworkaccessmanager.h \
    src/requester.h

DISTFILES += \
    qml/components/ImageDisplay.qml \
    qml/pages/Browser.qml \
    qml/pages/Bookmarks.qml \
    qml/pages/Bookmark.qml \
    qml/pages/Details.qml \
    qml/Model.qml \
    qml/qmldir \
    qml/pages/ImageViewer.qml \
    qml/pages/Settings.qml \
    qml/utils.js \
    qml/assets/gopherette.svg \
    qml/parserWorker.js \
    qml/pages/History.qml \
    rpm/harbour-gopherette.changes \
    qml/pages/About.qml \
    qml/assets/harbour-gopherette.png \
    qml/components/MenuButton.qml \
    qml/assets/gpl-3.0-standalone.html
