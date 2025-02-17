#!/bin/bash
source ~/emsdk/emsdk_env.sh > /dev/null 2>&1
#make -f pdfTeXMake
make -f XeTeXMake
echo "Build Completed."