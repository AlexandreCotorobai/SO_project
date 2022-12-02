## create a for loop to iterate throught the arguments
index=1

for arg in "$@"; do
    # get the first character of the argument
    firstchar=${arg:0:1}
    # echo "first char:" $firstchar
    # echo "arg len:" ${#arg}
    if [ $firstchar == "-" ] &&  [ ${#arg} -eq 2 ] ; then

        nextarg=$(($index+1))

        case ${arg:1:2} in
            c)
                echo "Next arg:" ${!nextarg}
                ;;

            # e)

            # u)

            # m)

            # M)

            # p)

            # r)

            # w)

            *)
                echo "Invalid flag"
                ;;
        esac

    fi


    index=$((index+1))
    echo "index" $index
done