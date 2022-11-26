#!/bin/bash

declare c_used=0
declare e_used=0
declare u_used=0
declare m_used=0
declare M_used=0
declare p_used=0
declare reverse=0
declare sortw=0

# default values
declare c="*"
# s=$(ps -p 1 -o lstart= | awk '{print $2 " " $3 " " substr($4,1,length($4)-3)}')
s=0
e=$(date +"%b %d %H:%M")
p_start=0


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
    comm=$(cat /proc/$pid/comm)
    # echo $c "<->" $comm

    #create a variable for the creation date and time without the seconds and year of the process
    #local creationdate=$(date -d "$(ps -p $pid -o lstart | tail -1 | awk '{print $1, $2, $3, $4}')" +"%b %d %H:%M")
    local creationdate=$(ps -p $pid -o lstart= | awk '{print $2 " " $3 " " substr($4,1,length($4)-3)}')
    

    #create a variable for the user of the process
    local user=$(ps -p $pid -o user | tail -1)

    #print a table with the process comm, user, pid, readbytes, writebytes, readbps, writebps, creationdate
    # printf "\n %-15s %-10s %+6s %+10s %+10s %+10s %+10s %+15s \n" "$comm" "$user" "$pid" "$readbytes" "$writebytes" "$readbps" "$writebps" "$creationdate"
    # if [[ reverse -eq 1 ]]; then
    #     echo "entrou"
    #     print | sort -k4 -n -r
    # fi
    # echo "entrou input"
    filter
}

function print() {

    if [[ reverse -eq 1 ]]; then

    
    printf "\n %-15s %-10s %+6s %+10s %+10s %+10s %+10s %+15s \n" "$comm" "$user" "$pid" "$readbytes" "$writebytes" "$readbps" "$writebps" "$creationdate"
}

function filter() {
    echo "Verificando... " $comm $creationdate
    if [[ $c_used -eq 1 ]]; then
        if [[ "$(ps -p $pid -o comm=)" != $c ]]; then
            return
        fi
    fi
    if [[ $s_used -eq 1 ]]; then
        if [[ $creationdate < $s ]]; then
            return
        fi
    fi
    if [[ $e_used -eq 1 ]]; then
        if [[ $creationdate > $e ]]; then
            return
        fi
    fi
    if [[ $u_used -eq 1 ]]; then
        if [[ $user != $u ]]; then
        # echo "User diferente"
            return
        # else
        #     echo "User igual"
        fi
        
    fi
    if [[ $m_used -eq 1 ]]; then
        if [[ $pid < $m ]]; then
            return
        fi
    fi
    if [[ $M_used -eq 1 ]]; then
        if [[ $pid > $M ]]; then
            return
        fi
    fi
    print
}
    # #name filter
    # if [[ "$(ps -p $pid -o comm=)" == $c ]]; then
    #     printf "\n %-15s %-10s %+6s %+10s %+10s %+10s %+10s %+15s \n" "$comm" "$user" "$pid" "$readbytes" "$writebytes" "$readbps" "$writebps" "$creationdate"
    # fi

    # if [[ $p_start -lt $p ]]; then
    #     printf "\n %-15s %-10s %+6s %+10s %+10s %+10s %+10s %+15s \n" "$comm" "$user" "$pid" "$readbytes" "$writebytes" "$readbps" "$writebps" "$creationdate"
    # else
    #     exit 1
    # fi 
    # p_start=$((p_start+1))

    #date filter
    # echo $s "<->" $e
    # if [[ $creationdate > $s && $creationdate < $e ]]; then
    #     printf "\n %-15s %-10s %+6s %+10s %+10s %+10s %+10s %+15s \n" "$comm" "$user" "$pid" "$readbytes" "$writebytes" "$readbps" "$writebps" "$creationdate"
    # fi

    # echo $m "<" $pid "<" $M
    # if [[ $pid > $m  && $pid < $M ]]; then
    #     printf "\n %-15s %-10s %+6s %+10s %+10s %+10s %+10s %+15s \n" "$comm" "$user" "$pid" "$readbytes" "$writebytes" "$readbps" "$writebps" "$creationdate"
    # fi

    
    
    # printf "\n %-15s %-10s %+6s %+10s %+10s %+10s %+10s %+15s \n" "$comm" "$user" "$pid" "$readbytes" "$writebytes" "$readbps" "$writebps" "$creationdate"


# function process_data(){

# }

function get_input(){
    while getopts "c:s:e:u:m:M:p:rw" opt; do
        case $opt in
            c)
                c="$OPTARG"
                
                # check if flag is used more than once
                if [[ $c_used == 1 ]]; then
                    echo "ERROR: -c flag already used"
                    exit 1
                fi

                c_used=1
                ;;
            s)
                # s=$(date -d "$OPTARG" +"%b %d %H:%M")
                s=$OPTARG
                # check if flag is used more than once
                if [[ $s_used == 1 ]]; then
                    echo "ERROR: -s flag already used"
                    exit 1
                fi

                s_used=1
                ;;
            e)
                e="$OPTARG"
                if [[ $e_used == 1 ]]; then
                    echo "ERROR: -e flag already used"
                    exit 1
                fi

                e_used=1
                ;;
            u)
                u="$OPTARG"
                # check if flag is used more than once
                if [[ $u_used == 1 ]]; then
                    echo "ERROR: -u flag already used"
                    exit 1
                fi
                # check if the user exists
                # if id "$u" &>/dev/null; then
                #     echo 'user found'              
                #     # filter by user
                #     # ps -u $u -o pid= | while read pid; do
                #     #     get_pid_stats $pid $s
                #     # done
                #     $u_used=1
                # else
                #     echo 'ERROR: user not found'
                # fi
                u_used=1
                ;;  

            m)
                m="$OPTARG"
                # check if flag is used more than once
                if [[ $m_uses == 1 ]]; then
                    echo "ERROR: -m flag already used"
                    exit 1
                fi
                m_used=1
                ;;

            M)
                M="$OPTARG"
                # check if flag is used more than once
                if [[ $M_used == 1 ]]; then
                    echo "ERROR: -M flag already used"
                    exit 1
                fi
                M_used=1
                ;;

            p)
                p=$OPTARG

                if [[ ! "${p}" =~ ^[0-9] ]]; then
                    echo "ERROR: -p flag must be followed by a number"
                    exit 1
                fi
                # check if flag is used more than onc
                if [[ $p_used == 1 ]]; then
                    echo "ERROR: -p flag already used"
                    exit 1
                fi

                p_used=1
                ;;
            r)
                # check if flag is used more than once
                if [[ $reverse == 1 ]]; then
                    echo "ERROR: -r flag already used"
                    exit 1
                else 
                    reverse=1
                fi

                ;;
            w)
                # check if flag is used more than once
                if [[ $sortw == 1 ]]; then
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
}

function main(){
    get_input "$@"

    printf "\n %-15s %-10s %+6s %+10s %+10s %+10s %+10s %+15s \n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"
    ps -u $USER -o pid= | while read pid; do
    # if the user has permission to read the /proc/[pid]/io file
        if [ -r /proc/$pid/io ] && [ -r /proc/$pid/status ] && [ -r /proc/$pid/comm ]; then
        # DUVIDA: necessario verificar status e comm?
            get_pid_stats $pid "${@: -1}"
        fi
    done
}

main "$@"