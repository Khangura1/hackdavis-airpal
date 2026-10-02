#include <QCoreApplication>

#include "qAQMS.h"

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    QAQMS aa;

    if (!aa.Init())
        return 1;

    return a.exec();
}