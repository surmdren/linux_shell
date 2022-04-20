#!/bin/bash
INT=-5

if [[ "$INT" =~ ^-?[0-9]+$ ]]; then

echo "INT is an integer."

else

echo "INT is not an integer." >&2

exit 1

fi
