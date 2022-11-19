#!/bin/bash

# This is a function that will write to the terminal the readbytes and writebytes of a process

function get_pid_stats() {
    local pid=$1

    local sleeptime=$2
    # echo "sleeptime:" $sleeptime

    # get the readbytes and writebytes of the process
    local readbytes=$(grep -E 'read_bytes' /proc/$pid/io | awk '{print $2}')

    local writebytes=$(grep -E 'write_bytes' -w /proc/$pid/io | awk '{print $2}')

    #sleep for sleeptime
    sleep $sleeptime

    # get the read and write bytes stats again
    local readbytes2=$(grep -E 'read_bytes' /proc/$pid/io | awk '{print $2}')

    local writebytes2=$(grep -E 'write_bytes' -w /proc/$pid/io | awk '{print $2}')

    # calculate the read bytes per second and write bytes per second

    local readbps=$((($readbytes2 - $readbytes) / $sleeptime))

    local writebps=$((($writebytes2 - $writebytes) / $sleeptime))

    #create a variable for the /proc/[pid]/comm file
    local comm=$(cat /proc/$pid/comm)

    #create a variable for the creation date and time without the seconds and year of the process
    local creationdate=$(date -d "$(ps -p $pid -o lstart | tail -1 | awk '{print $1, $2, $3, $4}')" +"%b %d %H:%M")

    #create a variable for the user of the process
    local user=$(ps -p $pid -o user | tail -1)

    #print a table with the process comm, user, pid, readbytes, writebytes, readbps, writebps, creationdate
    printf "\n %-20s %-10s %+6s %+10s %+10s %+10s %+10s %+15s \n" "$comm" "$user" "$pid" "$readbytes" "$writebytes" "$readbps" "$writebps" "$creationdate"

}


declare c_uses=0
declare e_uses=0
declare u_uses=0
declare m_uses=0
declare M_uses=0
declare p_uses=0
declare reverse=0
declare sortw=0


while getopts "c:s:e:u:m:M:p:rw" opt; do
    case $opt in
        c)
            c ="$OPTARG"

            # check if flag is used more than once
            if [[ $c_uses == 1 ]]; then
                echo "ERROR: -c flag already used"
                exit 1
            fi

            c_uses=1
            ;;
        s)
            s="$OPTARG"
            # check if flag is used more than once
            if [[ $s_uses == 1 ]]; then
                echo "ERROR: -s flag already used"
                exit 1
            fi

            s_uses=1
            ;;
        e)
            e="$OPTARG"

            ;;
        # u)

        # m)

        # M)

        p)
            p=$OPTARG

            if [[ ! "${p}" =~ ^[0-9] ]]; then
                echo "ERROR: -p flag must be followed by a number"
                exit 1
            fi
            # check if flag is used more than onc
            if [[ $p_uses == 1 ]]; then
                echo "ERROR: -p flag already used"
                exit 1
            fi

            p_uses=1
            ;;
        r)
            # check if flag is used more than once
            if [[ $reverse =~ 0 ]]; then
                echo "ERROR: -r flag already used"
                exit 1
            else 
                reverse=1
            fi

            ;;
        w)
            # check if flag is used more than once
            if [[ $sortw =~ 0 ]]; then
                echo "ERROR: -w flag already used"
                exit 1
            else 
                sortw=1
            fi

            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done


printf "\n %-20s %-10s %+6s %+10s %+10s %+10s %+10s %+15s \n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"
ps -u $USER -o pid= | while read pid; do
# if the user has permission to read the /proc/[pid]/io file
    if [ -r /proc/$pid/io ]; then
        get_pid_stats $pid "${@: -1}"
    fi
done

