#!/bin/sh

esc() {
	: # comment out the following line to disable color output
	printf '\33[%dm' "$1"
}

echo_red() {
	esc 31
	echo "$1"
	esc 0
}

echo_green() {
	esc 32
	echo "$1"
	esc 0
}

# check OS/architecture

if uname -a | grep -i 'x86_64' | grep -i -q 'linux'; then
	: # all good
else
	echo_red "Only 64-bit Linux is supported. This doesn't seem to be 64-bit Linux."
	exit 1
fi

cd 00
rm -f out00
make -s out00
if [ "$(cat out00)" != 'Hello, world!' ]; then
	echo_red 'Stage 00 failed.'
	exit 1
fi
rm -f out00
cd ..

cd 01
rm -f out0[01]
make -s out01
if [ "$(./out01)" != 'Hello, world!' ]; then
	echo_red 'Stage 01 failed.'
	exit 1
fi
rm -f out0[01]
cd ..


echo_green 'all stages completed successfully!'
