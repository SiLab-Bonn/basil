#/bin/sh
# This script removes vivado projects and temporary files
clear_vivado_files()
{
    cd vivado
    rm *.log *.jou *.str *.txt
    rm -rf designs reports output .Xil .ngc2edfcache
    cd ..
}

yExpr=$(locale yesexpr) 
printf 'This script removes vivado projects and temporary files. Continue? (y/n)'
old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg
if [ "$answer" != "${answer#${yExpr#^}}" ];then
    echo No; clear_vivado_files
else
    echo No
fi