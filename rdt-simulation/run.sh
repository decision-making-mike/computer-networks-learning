#!/bin/bash

# A simulation of "reliable data transfer"

data="$1"
if [[ -z "$data" ]]
then
    echo >&2 'Error, no data provided, exiting'
    exit 1
fi

height=5

transport_packet () {
    payload="$1"
    # Can there be any problems in Bash with variables having the same names as built-ins?
    type="$2"

    for (( x = 0 ; x < "$height" ; ++x ))
    do
        echo -n "$payload"
        # If I wanted not to move the payload automatically, but let the user decide how long they wait, I can replace "sleep 0.5" with "read". But then the user should be aware if they decide to keep "CTRL-D" pressed constantly. If they will not de-press "CTRL-D" at the latest right before the script will return, they will exit the terminal.
        sleep '0.5'
        echo -ne '\033[1D'
        echo -ne '\033[K'
        if [[ "$type" == 'ACK' ]]
        then echo -ne '\033[1A'
        else echo
        fi
    done
}

# I could also put "trap" before "tput". But then the user could be left with a trap of no purpose anymore if they issued "CTRL-C" between "trap" and "tput". Remarkable that they would not see the trap. I of course assume them to read the script before executing it, but nonetheless the fact of having the trap set could be overlooked. To avoid this problem, I have put "tput" before "trap". Now issuing "CTRL-C" in the aforementioned moment shall not left the trap. And as far as it then shall make the cursor invisible, such a change will be visible for the user, unlike the trap.
# One could say, "if you use "tput" anyway, why not also moving the cursor? Now if the user issues "CTRL-C" when the script is in the middle of transporting the payload, they are left with messy character leftover". Well, true that they are left so, but making so much cleanup feels to me like there would be done too much on the script side. Here I would rather do just the minimum for the script to run properly.
tput 'civis'
trap 'tput "cnorm" ; exit' SIGINT
clear

echo -n "$data"
echo -ne '\r'

sleep 1
for (( index = 0 ; index < "${#data}" ; ++index ))
do
    echo -ne '\033[K'
    echo "${data:$(( index + 1 )):${#data}}"

    # Transport the message with actual data.
    transport_packet "${data:$index:1}" ''

    echo -ne '\r'
    echo -ne '\033[K'
    echo -n "${data:0:$(( index + 1 ))}"
    echo -ne "\033[1A"
    echo -ne '\r'

    # Transport the "ACK" message.
    transport_packet '0' 'ACK'
done

echo -ne "\033[$(( height + 2 ))B"
tput 'cnorm'
trap SIGINT
