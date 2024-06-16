# !/bin/bash
set -eo pipefail #gdy bedzie jakis blad to skrypt sie zakonczy

export STAT_FILE_NAME=".mm"


usage(){
    cat <<EOF
    Usage: $0
    --help                  prints this help and exits
    --scan PATH             scans this path
    --find-duplicates PATH  finds duplicates in the subtree beginning in the path
    --force                 force update files, regardless of changes
    --ranking PATH NUMBER   rank NUMBER of biggest files in PATH
EOF
}

version_info(){
    cat <<EOF
    # Author           : Monika Zarudzka
    # Created On       : May 2023
    # Last Modified By : Monika Zarudzka
    # Last Modified On : 11 May 2023
    # Version          : 1.0
    #
    # Description      :  Tool enabling easy findind duplicates and large files in memory
    # 
    # Licensed under GPL (see /usr/share/common-licenses/GPL for more details
    # or contact # the Free Software Foundation for a copy)
EOF
}

rank_biggest_files(){
    local path=$1
    local number=$2
    
    result_file="$(mktemp --tmpdir="/tmp" result_file_$(date "+%Y%m%d_%H%M%S").XXXXX)"  #wszystkie pliki z podfolderow sa w result_file
    
    find ${path} -type d -printf "%p\n" | while read -r dir; do
        file_path="$(realpath "$dir/$STAT_FILE_NAME")"
        cat "${file_path}" >> ${result_file} 2> /dev/null || echo "Dir $(realpath $dir) is not scanned!"
    done

    #tutaj petla po wszystkich plikach w result_files:
    row_count="$(wc -l $result_file | cut -d' ' -f1)"
     
    if [[ $row_count -gt $number ]]; then
        row_count=$number
    fi
   
    sort -t ' ' -k4nr $result_file |  awk -v count="$row_count" 'NR <= count {print $1, $4}'
}


find_duplicates(){
    local path=$1
    result_file="$(mktemp --tmpdir="/tmp" result_file_$(date "+%Y%m%d_%H%M%S").XXXXX)"  #wszystkie pliki z podfolderow sa w result_file
    
    find ${path} -type d -printf "%p\n" | while read -r dir; do
        file_path="$(realpath "$dir/$STAT_FILE_NAME")"
        cat "${file_path}" >> ${result_file} 2> /dev/null || echo "Dir $(realpath $dir) is not scanned!"
    done

    #tutaj petla po wszystkich plikach w result_files:

    # prev_value="$(awk -F ' ' 'NR == 1 {print $3}' $result_file)"
    # prev_name="$(awk -F ' ' 'NR == 1 {print $1}' $result_file)"

    prev_value=""
    prev_name=""
    sort -t ' ' -k3 $result_file | \
    awk -v var="$prev_value" -v var_name="$prev_name" '{if ($3 == var) {print "Duplikatami", var_name, "sa:", $1; var = $3 ;prev_name = $1} else {var = $3; var_name = $1}}' $result_file

    #echo "Result file path: ${result_file}" #wyswietla sciezke do pliku z posortowanymi rekordami
}


stat_file(){
    
    local file_abs_path=${1}

    local file_name="$(basename "${file_abs_path}" | tr " " "_")" 
    local stat_result="$(stat -c "%Y %s" "${file_abs_path}")"
    local modify_time=$(echo "$stat_result" | cut -d' ' -f1)
    local file_size=$(echo "$stat_result" | cut -d' ' -f2)

    local file_row="$(grep "$file_name $modify_time" "$STAT_FILE_NAME")"  

    if [ -z "$file_row" ] ; then #len = 0
        local file_hash=$(md5sum "${file_abs_path}" | awk '{print $1}') #zglebic co to robi awk
        sed -i "/${file_name}/d" "$STAT_FILE_NAME" 
        echo "$file_name $modify_time $file_hash $file_size " >> $STAT_FILE_NAME 
    #else
        #echo "plik ${file_name} juz jest wpisany"
    fi

    
}

scan(){
    local path=${1}
    local force_scan=${2}
    local absolute_path=$(realpath "$path")

    cd "${absolute_path}"

    if [ "$force_scan" == "true" ]; then #zakladamy ze STAT_FILE_NAME istnieje
        rm $STAT_FILE_NAME > /dev/null 2>&1 || true # /dev/null to taki smietnik i samo sie usuwa
    fi

    touch "${STAT_FILE_NAME}"

    local dir="${absolute_path}""/*"
    
    for path in $dir
    do
        # if [[ "$path" == "$dir" ]]; then
            # continue
        # fi
        if [ -d "${path}" ] 
        then # Check if the subdir is a directory
            scan "${path}" "${force_scan}"
        else
            cd "${absolute_path}"
            stat_file "${path}" 
        fi

    done
}

main(){
  
    local path="."
    local mode=""
    local force_scan="false"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                usage
                exit 0
                ;;
            --scan|-s)
                shift 
                path="${1}"
                mode="scan"
                ;;
            --find-duplicates)
                shift 
                path="${1}"
                mode="find_duplicates"
                ;;
            --force)
                force_scan="true"
                ;;
            --version|-v)
                version_info
                exit 0
                ;;
            --ranking)
                shift 
                path="${1}"
                shift
                number="${1}"
                rank_biggest_files $path $number
                ;;
            -hv|-vh)
                version_info
                echo 
                usage
                exit 0
                ;;
            *)
            echo "Sorry, invalid argument!"
            echo "Try '--help' for instructions"
            exit 2
            ;;
        esac
        shift
    done

    if [[ $mode == "scan" ]]; then
        IFS=$'\n'
        scan $path $force_scan
        unset IFS
    elif [[ $mode == "find_duplicates" ]]; then
        find_duplicates $path
    fi

    echo "Script finished successfully"

}

main "$@"

