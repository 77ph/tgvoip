## If compiling on mac, comment out LIBS and CFLAGS below, and use the MacOS ones below
# Define macros for name of compiler
CXX= g++
LIBS=-ldl -lcrypto -lopus -lpthread
CFLAGS=-ggdb -O3 -Wall 
#LIBS+=/usr/local/lib/libtgvoip.a
LIBS+=libtgvoip.a
#LIBS+=-ltgvoip

### g++ -ldl -pthread -lopus -lcrypto tgvoipcall.cpp libs/libtgvoip.a -o tgvoipcall

OBJS=tgvoipcall.o
PROGS=tgvoipcall

most: tgvoipcall

all: $(PROGS)

tgvoipcall: tgvoipcall.o
        $(CXX) $^ -o $@ $(CFLAGS) $(LIBS)

clean:
        rm -f $(OBJS) $(PROGS) $(TESTS)
