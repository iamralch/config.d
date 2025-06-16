#!/bin/bash -x

replace() {
	rg -l "$1" | xargs sd "$1" "$2"
}
