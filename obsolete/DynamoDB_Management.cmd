@echo off
rem Created by Stephen Tse <Stephen.Xie@sa.gov.au>.
rem Version 2.1.1
echo This script sets up local / cloud DynamoDB environment on Windows for testing. Note that the aws cli commands used here can also be reused on other platforms.
echo.
echo To set up for local database, make sure to run the database executable, set up the endpoint, and prepare the data to be written to the database before running this script.

rem Delete the content of endpoint if used to debug the cloud version of DynamoDB
rem set endpoint=--endpoint-url http://localhost:8000
set endpoint=
set db_input_data="file://devices.json"
set table_name="Device"
rem set primary key below
set PK="id"
echo.
if defined endpoint (
    echo *** This script is connected to the local database.
) else (
    echo *** This script is connected to the online database.
)


:menu
echo.
echo.
echo Current table under management: %table_name%
echo.
echo ** Available Command List ***************
echo 1. List existing tables
echo 2. Create a new table
echo 3. Populate the table with data
echo 4. Get all data from the table
echo 5. Drop the table
echo [AnyOtherKey]. Exit the program
echo.
set /p usr_input="Type in the corresponding command index then press ENTER: "
if %usr_input%==1 goto list_tables
if %usr_input%==2 goto create_table
if %usr_input%==3 goto populate_table
if %usr_input%==4 goto get_contents
if %usr_input%==5 goto drop_table
exit


:list_tables
aws dynamodb list-tables %endpoint%
goto menu


:create_table
echo Creating new table...
rem Doc: http://docs.aws.amazon.com/cli/latest/reference/dynamodb/create-table.html
rem Note: provisioned throughput may needs some tweaking in actual production. More info: http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ProvisionedThroughput.html#HowItWorks.ProvisionedThroughput.Manual
aws dynamodb create-table ^
    --table-name %table_name% ^
    --attribute-definitions ^
        AttributeName=%PK%,AttributeType=S ^
    --key-schema ^
        AttributeName=%PK%,KeyType=HASH ^
    --provisioned-throughput ^
        ReadCapacityUnits=1,WriteCapacityUnits=5 ^
    %endpoint%
        
echo.
echo Table %table_name% created!
goto menu


:populate_table
echo Populating table with data...
rem Doc: http://docs.aws.amazon.com/cli/latest/reference/dynamodb/batch-write-item.html
aws dynamodb batch-write-item --request-items %db_input_data% %endpoint%
    
echo.
echo Table %table_name% populated!
goto menu


:get_contents
echo Retrieving all data from table...
aws dynamodb scan --table-name %table_name% %endpoint%
echo.
echo Data retrieved!
goto menu


:drop_table    
echo Dropping table...
aws dynamodb delete-table --table-name %table_name% %endpoint%
echo.
echo Table %table_name% dropped!
goto menu
