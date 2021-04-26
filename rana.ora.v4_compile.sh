download oracle instantclient and sdk option.

set environment variables.
setx CGO_CFLAGS "C:\instantclient_12_1\sdk\include"
setx CGO_LDFLAGS "-LC:\instantclient_12_1 -loci"

install MSYS2

# Update pacman
pacman -Su
# Close terminal and open a new terminal
# Update all other packages
pacman -Su
# Install pkg-config and gcc
pacman -S mingw64/mingw-w64-x86_64-pkg-config mingw64/mingw-w64-x86_64-gcc

c:\msys64\mingw64\lib\pkgconfig\oci8.pc
-------------------------------------------------------------------------------------------------------
version=12.1
build=client64

libdir=C:/instantclient_12_1/sdk/lib/msvc
includedir=C:/instantclient_12_1/sdk/include

glib_genmarshal=glib-genmarshal
gobject_query=gobject-query
glib_mkenums=glib-mkenums

Name: oci8
Description: Oracle database engine
Version: ${version}
Libs: -L${libdir} -loci
Libs.private:
Cflags: -I${includedir}
--------------------------------------------------------------------------------------------------------
setx PKG_CONFIG_PATH "C:\msys64\mingw64\lib\pkgconfig"
setx PATH "%PATH%;C:\msys64\mingw64\bin"


then create your project inside your %GO_PATH% like this
c:/go_workspace/example.com/user/go_oracle_test

add ora v.4 package as depedency
go get gopkg.in/rana/ora.v4