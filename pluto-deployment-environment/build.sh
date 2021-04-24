#!/bin/bash

"
Run this as root to your new (Ubuntu based)
That will save you up to 70% compared to using a 'hosted' service


"

wget https://julialang-s3.julialang.org/bin/linux/x64/1.6/julia-1.6.1-linux-x86_64.tar.gz
tar zxvf julia-1.6.1-linux-x86_64.tar.gz
rm julia-1.6.1-linux-x86_64.tar.gz
ln -s `pwd`/julia-1.6.1/bin/julia /usr/local/bin/julia


git clone https://github.com/pankgeorg/PlutoCon2021-demos#main

cd PlutoCon2021-demos
julia --project="pluto-deployment-environment" -e "using PlutoSliderServer; runrepository()"