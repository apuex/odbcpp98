REM Why boost 1.34.1?
REM Because 1.34.1 is the last version that supports vc6. 

REM build bjam.exe

REM cd E:\dist-vc6\packages\boost_1_34_1\tools\jam
REM build_dist.bat
REM 
REM cd E:\dist-vc6\packages\boost_1_34_1\
REM copy E:\dist-vc6\packages\boost_1_34_1\tools\jam\src\boost-jam-3.1.14-1-ntx86\bjam.exe .

bjam install --prefix=E:\dist-vc6 ^
--build-dir=E:\dist-vc6\build-boost ^
--build-type=complete ^
--without-python ^
toolset=msvc stage link=static ^
define=BOOST_USE_WINAPI_VERSION=0x0501 ^
define=_WIN32_WINNT=0x0501 ^
define=_CRT_SECURE_NO_WARNINGS=1 ^
address-model=32 ^
architecture=x86


REM build with vc6

REM bjam install ^
REM --prefix=E:\dist-vc6 ^
REM --build-dir=E:\dist-vc6\build-boost ^
REM --build-type=complete ^
REM --without-python ^
REM toolset=msvc stage link=static ^
REM -sMSVCNT="\"\"C:\Program Files\Microsoft Visual Studio\VC98\"\""
