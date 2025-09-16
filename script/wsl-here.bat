@echo off
REM 🧠 Get current directory and convert to WSL path
set "winpath=%cd%"
set "drive=%winpath:~0,1%"
set "rest=%winpath:~2%"
set "wslpath=/mnt/%drive:~0,1%%rest:\=/%"

REM 🔽 Force lowercase drive letter
for %%A in (%drive%) do set "wslpath=/mnt/%%A%rest:\=/%"
set "wslpath=%wslpath:C=c%"
set "wslpath=%wslpath:D=d%"
set "wslpath=%wslpath:E=e%"
set "wslpath=%wslpath:F=f%"
set "wslpath=%wslpath:G=g%"
set "wslpath=%wslpath:H=h%"
set "wslpath=%wslpath:I=i%"
set "wslpath=%wslpath:J=j%"
set "wslpath=%wslpath:K=k%"
set "wslpath=%wslpath:L=l%"
set "wslpath=%wslpath:M=m%"
set "wslpath=%wslpath:N=n%"
set "wslpath=%wslpath:O=o%"
set "wslpath=%wslpath:P=p%"
set "wslpath=%wslpath:Q=q%"
set "wslpath=%wslpath:R=r%"
set "wslpath=%wslpath:S=s%"
set "wslpath=%wslpath:T=t%"
set "wslpath=%wslpath:U=u%"
set "wslpath=%wslpath:V=v%"
set "wslpath=%wslpath:W=w%"
set "wslpath=%wslpath:X=x%"
set "wslpath=%wslpath:Y=y%"
set "wslpath=%wslpath:Z=z%"
set "wslpath=%wslpath:A=a%"
set "wslpath=%wslpath:B=b%"
REM Add more drive letters if needed

REM 🌀 Launch WSL in current directory
wsl.exe --cd "%wslpath%"
