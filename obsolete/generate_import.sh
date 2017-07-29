#!/bin/bash
# This generates .json import file ready for DynamoDB batchWrite() from aws-cli tool
# Created by Stephen Tse <Stephen.Xie@sa.gov.au>
# Version 1.1.2

counter=0
# -- Set up variables here ---------
import_file="sample.csv"  # !! must include an empty last line in the import file !!
export_file="devices.json"
table_name="Device"

agency="DPTI"  # the additional field to be put into each item
# ----------------------------------


echo "Generating .json import file ready for DynamoDB batchWrite()..."

# Create a new file and the starting content
> $export_file
echo "{" >> $export_file
echo "    \"${table_name}\": [" >> $export_file

IFS=","  # set delimiter to ","
counter=0
sed 1d "${import_file}" | {  # skip first line of file (column name)
    while read longitude latitude
    do  # for each line (item)
        # create hashed id for each item; use md5 hashing function
        id=$(echo -n $longitude$latitude$agency | md5sum | cut --delimiter=' ' --fields=1)
        # then write main content to file
        echo "        {" >> $export_file
        echo "            \"PutRequest\": {" >> $export_file
        echo "                \"Item\": {" >> $export_file
        echo "                    \"id\": {\"S\": \"${id}\"}," >> $export_file
        echo "                    \"longitude\": {\"N\": \"${longitude}\"}," >> $export_file
        echo "                    \"latitude\": {\"N\": \"${latitude}\"}," >> $export_file
        echo "                    \"agency\": {\"S\": \"${agency}\"}" >> $export_file
        echo "                }" >> $export_file
        echo "            }" >> $export_file
        printf "        },\n\n" >> $export_file
        
        ((counter++))
    done

    # wrap up the file
    truncate --size=-3 "${export_file}"  # remove the trailing bits (",\n\n") from the file
    printf "\n\n    ]\n" >> $export_file
    echo "}" >> $export_file

    printf "\nImport file \"$export_file\" generated! Added $counter items.\n"
}
# used command grouping to keep $counter inside the same subshell, otherwise a new counter will be created outside
# the while loop. More info: http://mywiki.wooledge.org/BashFAQ/024
