#!/bin/bash

declare c_used=0
declare e_used=0
declare u_used=0
declare m_used=0
declare M_used=0
declare p_used=0
declare reverse=0
declare sortw=0
declare i=0
declare -a allSavedPids
declare -A saveReadBytes
declare -A saveWriteBytes
declare p=-1
declare -a validadeMonths=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")

# default values
# s=$(ps -p 1 -o lstart= | awk '{print $2 " " $3 " " substr($4,1,length($4)-3)}')
# s=0
# e=$(date +"%b %d %H:%M")

# This is a function that will write to the terminal the readbytes and writebytes of a process

function get_pid_stats() {
    local sleeptime=$1
    # echo $sleeptime
    for pid in $(ps -eo pid= | tail -n +2); do
        if [ -r /proc/$pid/io ] && [ -r /proc/$pid/status ] && [ -r /proc/$pid/comm ]; then
            local readbytes=$(grep -E 'rchar' /proc/$pid/io | awk '{print $2}')
            saveReadBytes[$pid]=$readbytes

            local writebytes=$(grep -E 'wchar' -w /proc/$pid/io | awk '{print $2}')
            saveWriteBytes[$pid]=$writebytes
        fi
    done

    sleep $sleeptime

    for pid in $(ps -eo pid= | tail -n +2); do
        if [ -r /proc/$pid/io ] && [ -r /proc/$pid/status ] && [ -r /proc/$pid/comm ]; then
            local readbytes1=$(grep -E 'rchar' /proc/$pid/io | awk '{print $2}')

            declare readbytes2=$(($readbytes1 - ${saveReadBytes[$pid]}))

            # echo "sub " $readbytes1 ${saveReadBytes[$pid]}
            # echo "res " $readbytes2

            declare readbps=$((($readbytes2) / $sleeptime))

            local writebytes1=$(grep -E 'wchar' -w /proc/$pid/io | awk '{print $2}')

            declare writebytes2=$(($writebytes1 - ${saveWriteBytes[$pid]}))

            declare writebps=$((($readbytes2) / $sleeptime))

            declare comm=$(cat /proc/$pid/comm)
            comm=${comm// /}
            # echo $c "<->" $comm

            declare creationdate=$(ps -p $pid -o lstart= | awk '{print $2 " " $3 " " substr($4,1,length($4)-3)}')
            
            declare user=$(ps -p $pid -o user | tail -1)

            filter

        fi
    done
}

# function print() {
#     printf "\n %-15s %-10s %+6s %+10s %+10s %+10s %+10s %+15s \n" "$comm" "$user" "$pid" "$readbytes" "$writebytes" "$readbps" "$writebps" "$creationdate"
# }
comm=${comm// /}

function print() {
    if [[ $sortw -eq 1 ]]; then
        if [[ $reverse -eq 1 ]]; then
            printf '%s \n' "${allSavedPids[@]}" | sort -k7 -n | head -n $p
        else
            printf '%s \n' "${allSavedPids[@]}" | sort -r -k7 -n | head -n $p
        fi
    else
        if [[ $reverse -eq 1 ]]; then
            printf '%s \n' "${allSavedPids[@]}" | sort -k6 -n | head -n $p
        else
            printf '%s \n' "${allSavedPids[@]}" | sort -r -k6 -n | head -n $p
        fi
    fi

}


function filter() {
    # echo "Verificando... " $comm $creationdate
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

    # if [[ $p_used -eq 1 ]]; then
    #     if [[ $i -ge $p ]]; then
    #         return
    #     fi
    # fi

    allSavedPids[$i]=$(printf "%-20s %-10s %+6s %+10s %+10s %+10s %+10s %+15s" "$comm" "$user" "$pid" "$readbytes2" "$writebytes2" "$readbps" "$writebps" "$creationdate")
    i=$((i+1))
}


function get_input(){   

    if ! [[ "${@: -1}" =~ ^[0-9]+$ ]]; then
        echo "ERROR: The last argument must be a number"
        exit 1
    fi

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

                # validade date format %b %d %H:%M
                if [[ $s =~ ^[A-Za-z]{3}\ [0-9]{2}\ [0-9]{2}:[0-9]{2}$ && "${validadeMonths[*]}" =~ "${s:0:3}" ]]; then
                    s_used=1
                else
                    echo "ERROR: Invalid date format"
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

                if [[ $s =~ ^[A-Za-z]{3}\ [0-9]{2}\ [0-9]{2}:[0-9]{2}$ && "${validadeMonths[*]}" =~ "${s:0:3}" ]]; then
                    s_used=1
                else
                    echo "ERROR: Invalid date format"
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
                if ! id "$u" &>/dev/null; then
                    echo 'user found'              
                    exit 1
                fi
                u_used=1
                ;;  

            m)
                m=$OPTARG
                # check if flag is used more than once
                if [[ $m_uses == 1 ]]; then
                    echo "ERROR: -m flag already used"
                    exit 1
                fi

                if ! [[ $m =~ ^[0-9]+$ ]]; then
                    echo "ERROR: -m flag must be an integer"
                    exit 1
                fi

                # corrigir que ficheiro tipo: rwstat_remake.s & Web Content - não funciona

                m_used=1
                ;;

            M)
                M=$OPTARG
                # check if flag is used more than once
                if [[ $M_used == 1 ]]; then
                    echo "ERROR: -M flag already used"
                    exit 1
                fi

                if ! [[ $M =~ ^[0-9]+$ ]]; then
                    echo "ERROR: -m flag must be an integer"
                    exit 1
                fi

                # corrigir que ficheiro tipo: rwstat_remake.s & Web Content - não funciona

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
    count=0
    printf "\n%-20s %-10s %+6s %+10s %+10s %+10s %+10s %+15s \n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"
    get_pid_stats "${@: -1}"
        # fi
    # done

    print
}

main "$@"