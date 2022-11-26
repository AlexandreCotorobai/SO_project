declare -a tas=("tua tia" "tua mae" "tua avo")
echo "-------------------"
for ta in ${tas[@]}; do
    echo $ta
done
echo "-------------------"
for ta in "${tas[@]}"; do
    echo $ta
done
echo "-------------------"
for ta in ${tas[*]}; do
    echo $ta
done
echo "-------------------"
for ta in "${tas[*]}"; do
    echo $ta
done