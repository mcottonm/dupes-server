for ((i=0;i<1000000;i++)); do 
    printf "%d,192.168.%d.%d,2023-10-22 17:51:59\n" "$((RANDOM % 500000))" "$((RANDOM % 256))" "$((RANDOM % 256))"
done