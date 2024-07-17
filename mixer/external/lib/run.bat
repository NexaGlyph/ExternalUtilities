cl /c /EHsc /MD /I ../ lib.c /link WinMM.lib
ar rcs libaudio.lib lib.obj
lib /OUT:libaudio.lib /NODEFAULTLIB lib.obj WinMM.lib
link /DLL /OUT:libaudio.dll lib.obj /link WinMM.lib
C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64 x64