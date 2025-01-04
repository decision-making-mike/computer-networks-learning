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
    lost="$3"

    if [[ "$lost" -eq 1 ]]
    then return 1
    fi

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

send_data_packet () {
    echo -ne '\033[K'
    echo "${data:$(( index + 1 )):${#data}}"
}

send_ack_packet () {
    echo -ne '\r'
    echo -ne '\033[K'
    echo -n "${data:0:$(( index + 1 ))}"
    echo -ne "\033[1A"
    echo -ne '\r'
}

# I could also put "trap" before "tput". But then the user could be left with a trap of no purpose anymore if they issued "CTRL-C" between "trap" and "tput". Remarkable that they would not see the trap. I of course assume them to read the script before executing it, but nonetheless the fact of having the trap set could be overlooked. To avoid this problem, I have put "tput" before "trap". Now issuing "CTRL-C" in the aforementioned moment shall not left the trap. And as far as it then shall make the cursor invisible, such a change will be visible for the user, unlike the trap.
# One could say, "if you use "tput" anyway, why not also moving the cursor? Now if the user issues "CTRL-C" when the script is in the middle of transporting the payload, they are left with messy character leftover". Well, true that they are left so, but making so much cleanup feels to me like there would be done too much on the script side. Here I would rather do just the minimum for the script to run properly.
tput 'civis'
trap 'tput "cnorm" ; exit' SIGINT
clear

echo -n "$data"
echo -ne '\r'

sleep 1
ack_received=1
for (( index = 0 ; index < "${#data}" ; ))
do
    # TODO Actual ACK awaiting implementation (read -t?)
    {
        send_data_packet \
            && transport_packet "${data:$index:1}" '' 0 \
            && send_ack_packet \
            && transport_packet '0' 'ACK' "(( RANDOM % 2 ))" \
            && ack_received=1
    } || ack_received=0

    if [[ "$ack_received" -eq 1 ]]
    then index="$(( index + 1 ))"
    else
        # We jump straight to the sender, and not a fixed number of lines, because we assume that we cannot know in which line the packet has been lost.
        echo -ne "\033[;H"
    fi
done

echo -ne "\033[$(( height + 2 ))B"
tput 'cnorm'
trap SIGINT
