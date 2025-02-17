#!/bin/bash
source ~/emsdk/emsdk_env.sh > /dev/null 2>&1
make -f pdfTeXMake clean
make -f XeTeXMake clean
echo "Clean Completed."