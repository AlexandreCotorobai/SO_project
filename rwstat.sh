#!/bin/bash

declare c_used=0    # Variável de controlo de uso da flag -c
declare e_used=0    # Variável de controlo de uso da flag -e
declare u_used=0    # Variável de controlo de uso da flag -u
declare m_used=0    # Variável de controlo de uso da flag -m
declare M_used=0    # Variável de controlo de uso da flag -M
declare p_used=0    # Variável de controlo de uso da flag -p
declare reverse=0   # Variável de controlo de uso da flag -r
declare sortw=0     # Variável de controlo de uso da flag -s
declare i=0         # Variável usada para iteração na função filter()
declare -a allSavedPids    # Array usado para guardar linhas de informação que serão impressas na tabela 
declare -A saveReadBytes   # Array usado para salvar o readbytes de cada pid
declare -A saveWriteBytes  # Array usado para salvar o writebytes de cada pid
declare p=-1               # Valor default para a flag -p, quando é -1 irá dar display de todo os processos
declare -a validadeMonths=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
                           # Array que contém o formato válido de cada mês
declare argCount=0         # Variável que conta o número de flags e o numero de argumentos



function menu() {
    echo "-------------------------------------------------------------------------------------------------------"
    echo "Modo de utilização: ./rwstat.sh [opções] [sleeptime]"
    echo "Opções válidas:"
    echo "    -c          : Seleção de processos a utilizar através de uma expressão regular"
    echo "    -u          : Seleção de processos a visualizar através do nome do utilizador"
    echo "    -s          : Seleção de processos a visualizar num periodo temporal - data mínima (Mes d hh:mm)"
    echo "    -e          : Seleção de processos a visualizar num periodo temporal - data máxima (Mes d hh:mm)"
    echo "    -m          : Seleção de processos a visualizar num número mínimo de pid"
    echo "    -M          : Seleção de processos a visualizar num número máximo de pid"
    echo "    -p          : Número de processos a visualizar"
    echo "    -r          : Ordenação da tabela por ordem reversa"
    echo "    -w          : Ordenação da tabela pOR RATEW"
    echo "Último argumento: O último argumento passado tem de ser um número"
    echo "-------------------------------------------------------------------------------------------------------"
}

function get_pid_stats() {
    local sleeptime=$1

    for pid in $(ps -eo pid= | tail -n +2); do                                              # percorre todos os processos
        if [ -r /proc/$pid/io ] && [ -r /proc/$pid/status ] && [ -r /proc/$pid/comm ]; then # verifica as permisoes de read de cada processo
            local readbytes=$(grep -E 'rchar' /proc/$pid/io | awk '{print $2}') 
            saveReadBytes[$pid]=$readbytes                                                  # guarda o readbytes inicial num dicionario associado ao pid do processo

            local writebytes=$(grep -E 'wchar' -w /proc/$pid/io | awk '{print $2}')
            saveWriteBytes[$pid]=$writebytes                                                # guarda o writebytes inicial num dicionario associado ao pid do processo
        fi
    done

    sleep $sleeptime    # tempo de espera entre uma leitura e outra para que seja possivel calcular a diferença
    

    for pid in $(ps -eo pid= | tail -n +2); do                                                  # percorre novamente todos os processos
        if [ -r /proc/$pid/io ] && [ -r /proc/$pid/status ] && [ -r /proc/$pid/comm ]; then     # verifica as permisoes de read de cada processo
            if [[ ! ${!saveReadBytes[@]} =~ "${pid}" ]]; then                               # verifica se o pid do processo está no dicionario, ..
                continue                                                                    # .. evita crashes caso um novo processo seja criado durante o sleeptime
            fi
            local readbytes1=$(grep -E 'rchar' /proc/$pid/io | awk '{print $2}')

            declare readbytes2=$(($readbytes1 - ${saveReadBytes[$pid]}))                # calcula a diferença entre o readbytes atual e o readbytes inicial

            declare readbps=$((($readbytes2) / $sleeptime))                             # calcula o readbytes por segundo

            local writebytes1=$(grep -E 'wchar' -w /proc/$pid/io | awk '{print $2}') 

            declare writebytes2=$(($writebytes1 - ${saveWriteBytes[$pid]}))             # calcula a diferença entre o writebytes atual e o writebytes inicial

            declare writebps=$((($writebytes2) / $sleeptime))                           # calcula o writebytes por segundo

            declare comm=$(cat /proc/$pid/comm)                                         # guarda o nome do processo
            comm=${comm// /}                                                            # remove os espaços do nome do processo (caso existam)

            declare creationdate=$(ps -p $pid -o lstart= | awk '{print $2 " " $3 " " substr($4,1,length($4)-3)}') # guarda a data de criação do processo
            
            declare user=$(ps -p $pid -o user | tail -1)                                # guarda o utilizador que criou o processo

            filter  # invocação da função filter

        fi
    done
}

function print() {
    if [ ${#allSavedPids[@]} -eq 0 ]; then                                      # verifica se o array allSavedPids está vazio (ou seja, se não existem processos que satisfazem os critérios)
        printf "No process found matching your search\n"
    fi
    if [[ $sortw -eq 1 ]]; then                                                 # verifica se a flag -w foi usada
        if [[ $reverse -eq 1 ]]; then                                           # verifica se a flag -r foi usada
            printf '%s \n' "${allSavedPids[@]}" | sort -k7 -n | head -n $p      # ordena o array allSavedPids por ordem crescente de writebytes por segundo e imprime os primeiros p processos
        else
            printf '%s \n' "${allSavedPids[@]}" | sort -r -k7 -n | head -n $p   # ordena o array allSavedPids por ordem decrescente de writebytes por segundo e imprime os primeiros p processos
        fi
    else
        if [[ $reverse -eq 1 ]]; then
            printf '%s \n' "${allSavedPids[@]}" | sort -k6 -n | head -n $p      # ordena o array allSavedPids por ordem crescente de readbytes por segundo e imprime os primeiros p processos
        else
            printf '%s \n' "${allSavedPids[@]}" | sort -r -k6 -n | head -n $p   # ordena o array allSavedPids por ordem decrescente de readbytes por segundo e imprime os primeiros p processos
        fi
    fi

}


function filter() {
    if [[ $c_used -eq 1 ]]; then                        # caso a flag -c tenha sido usada, verifica se o nome do processo é igual ao nome passado como argumento
        if ! [[ "$(ps -p $pid -o comm=)" =~ ^$c+$ ]]; then   # caso não seja, a função retorna e o processo é ignorado
            return
        fi
    fi
    if [[ $s_used -eq 1 ]]; then                        # caso a flag -s tenha sido usada, verifica se a creationdate é maior que a data passada como argumento
        if [[ $creationdate < $s ]]; then               # caso não seja, a função retorna e o processo é ignorado
            return
        fi
    fi
    if [[ $e_used -eq 1 ]]; then                        # caso a flag -e tenha sido usada, verifica se a creationdate é menor que a data passada como argumento 
        if [[ $creationdate > $e ]]; then               # caso não seja, a função retorna e o processo é ignorado
            return
        fi
    fi
    if [[ $u_used -eq 1 ]]; then                        # caso a flag -u tenha sido usada, verifica se o utilizador que criou o processo é igual ao nome passado como argumento
        if [[ $user != $u ]]; then                      # caso não seja, a função retorna e o processo é ignorado
            return
        fi
        
    fi
    if [[ $m_used -eq 1 ]]; then                        # caso a flag -m tenha sido usada, verifica se o pid do processo é maior que o valor passado como argumento
        if [[ $pid -lt $m ]]; then                        # caso não seja, a função retorna e o processo é ignorado
            return
        fi
    fi
    if [[ $M_used -eq 1 ]]; then                        # caso a flag -M tenha sido usada, verifica se o pid do processo é menor que o valor passado como argumento
        if [[ $pid -gt $M ]]; then                        # caso não seja, a função retorna e o processo é ignorado
            return
        fi
    fi
    # caso o processo tenha passado por todas as verificações, é adicionado ao array allSavedPids já formatado
    allSavedPids[$i]=$(printf "%-20s %-10s %+6s %+10s %+10s %+10s %+10s %+15s" "$comm" "$user" "$pid" "$readbytes2" "$writebytes2" "$readbps" "$writebps" "$creationdate")
    i=$((i+1))
}


function get_input(){  
        
    if [[ $# == 0 ]]; then                  # verifica se não foram passados argumentos
        echo "ERROR: Has to have as least one argument (sleep time, in seconds)"
        exit 1
    fi 

    while getopts "c:s:e:u:m:M:p:rw" opt; do # lê os argumentos passados
        case $opt in
            c)
                c="$OPTARG"
                
                # check if flag is used more than once
                if [[ $c_used == 1 ]]; then
                    echo "ERROR: -c flag already used"
                    menu
                    exit 1
                fi

                argCount=$(($argCount+2))
                c_used=1
                ;;
            s)
                s=$OPTARG
                # check if flag is used more than once
                if [[ $s_used == 1 ]]; then
                    echo "ERROR: -s flag already used"
                    menu
                    exit 1
                fi

                # valida o formato do argumento passado como data
                local mes=${s:0:3}
                if [[ $s =~ ^[A-Za-z]{3}\ [0-9]{1,2}\ [0-9]{1,2}:[0-9]{2}$ && "${validadeMonths[*]}" =~ "${mes^}" ]]; then
                    s_used=1
                else
                    echo "ERROR: Invalid date format"
                    menu
                    exit 1
                fi
                
                argCount=$(($argCount+2))

                s_used=1
                ;;
            e)
                e="$OPTARG"
                if [[ $e_used == 1 ]]; then
                    echo "ERROR: -e flag already used"
                    menu
                    exit 1
                fi

                # valida o formato do argumento passado como data
                local mes=${s:0:3}
                if [[ $s =~ ^[A-Za-z]{3}\ [0-9]{1,2}\ [0-9]{1,2}:[0-9]{2}$ && "${validadeMonths[*]}" =~ "${mes^}" ]]; then
                    s_used=1
                else
                    echo "ERROR: Invalid date format"
                    menu
                    exit 1
                fi
                argCount=$(($argCount+2))

                e_used=1
                ;;
            u)
                u="$OPTARG"
                # check if flag is used more than once
                if [[ $u_used == 1 ]]; then
                    echo "ERROR: -u flag already used"
                    menu
                    exit 1
                fi
                # verifica se o utilizador passado como argumento existe
                if ! id "$u" &>/dev/null; then
                    echo 'ERROR: User not found'
                    menu              
                    exit 1
                fi
                argCount=$(($argCount+2))
                u_used=1
                ;;  

            m)
                m=$OPTARG
                # check if flag is used more than once
                if [[ $m_used == 1 ]]; then
                    echo "ERROR: -m flag already used"
                    menu
                    exit 1
                fi
                # verifica se o argumento passado é um número
                if ! [[ $m =~ ^[0-9]+$ ]]; then
                    echo "ERROR: -m flag must be an integer"
                    menu
                    exit 1
                fi
                argCount=$(($argCount+2))

                m_used=1
                ;;

            M)
                M=$OPTARG
                # check if flag is used more than once
                if [[ $M_used == 1 ]]; then
                    echo "ERROR: -M flag already used"
                    menu
                    exit 1
                fi
                # verifica se o argumento passado é um número
                if ! [[ $M =~ ^[0-9]+$ ]]; then
                    echo "ERROR: -M flag must be an integer"
                    menu
                    exit 1
                fi
                argCount=$(($argCount+2))

                M_used=1
                ;;

            p)
                p=$OPTARG
                # verifica se o argumento passado é um número
                if [[ ! "${p}" =~ ^[0-9]+$ ]]; then
                    echo "ERROR: -p flag must be followed by an integer"
                    menu
                    exit 1
                fi
                # check if flag is used more than once
                if [[ $p_used == 1 ]]; then
                    echo "ERROR: -p flag already used"
                    menu
                    exit 1
                fi
                argCount=$(($argCount+2))
                p_used=1
                ;;
            r)
                # check if flag is used more than once
                if [[ $reverse == 1 ]]; then
                    echo "ERROR: -r flag already used"
                    menu
                    exit 1
                else 
                    reverse=1
                fi
                argCount=$(($argCount+1))

                ;;
            w)
                # check if flag is used more than once
                if [[ $sortw == 1 ]]; then
                    echo "ERROR: -w flag already used"
                    menu
                    exit 1
                else 
                    sortw=1
                fi
                argCount=$(($argCount+1))

                ;;
            \?)
                echo "Invalid option"
                exit 1
                ;;
            :)
                echo "Option -$OPTARG requires an argument." >&2
                exit 1
                ;;
        esac
    done

    if ! [[ "${@: -1}" =~ ^[0-9]+$ ]]; then                     # verifica se o último argumento, que tem que ser necessáriamente o valor do sleep time, é um número
        echo "ERROR: The last argument must be a integer (sleep time, in seconds)"
        exit 1
    fi
    local nrInputs=$(($#-1)) # número de argumentos passados, excluindo o último, que é o sleep time

    if [[ $nrInputs -ne $argCount ]]; then  # verifica se o número de flags e argumentos passados é igual ao número de argumentos esperados
        echo "ERROR: Sleep time must exist and must be the last argument" 
        exit 1
    fi
}

function main(){
    get_input "$@"
    printf "\n%-20s %-10s %+6s %+10s %+10s %+10s %+10s %+15s \n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"
    get_pid_stats "${@: -1}"

    print
}

main "$@"