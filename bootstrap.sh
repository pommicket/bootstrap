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

echo 'Processing stage 00...'
cd 00
rm -f out00
make -s out00
if [ "$(cat out00)" != 'Hello, world!' ]; then
	echo_red 'Stage 00 failed.'
	exit 1
fi
rm -f out00
cd ..

echo 'Processing stage 01...'
cd 01
rm -f out*
make -s out01
if [ "$(./out01)" != 'Hello, world!' ]; then
	echo_red 'Stage 01 failed.'
	exit 1
fi
rm -f out01
cd ..

echo 'Processing stage 02...'
cd 02
rm -f out*
make -s out02
if [ "$(./out02)" != 'Hello, world!' ]; then
	echo_red 'Stage 02 failed.'
	exit 1
fi
cd ..

echo 'Processing stage 03...'
cd 03
rm -f out*
make -s out03
if [ "$(./out03)" != 'Hello, world!' ]; then
	echo_red 'Stage 03 failed.'
	exit 1
fi
cd ..

echo 'Processing stage 04a...'
cd 04a
rm -f out*
make -s out04a
if [ "$(cat out04a)" != "$(printf '\n\nHello, world!')" ]; then
	echo_red 'Stage 04a failed.'
	exit 1
fi
cd ..


echo_green 'all stages completed successfully!'
