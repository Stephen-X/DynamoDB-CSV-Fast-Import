# CSV Fast Import to DynamoDB
**Author:** Stephen Tse \<Stephen.Xie@sa.gov.au\>  
**Last Edit:** 19/07/2017  
**Reflecting Project Version:** 1.0.3  
**How to read this file with format:** On Windows, open in Visual Studio Code, press `Ctrl`+`K`, release the keys, then press `V` to open the built-in markdown preview window.

This is a small project created to fast import data stored in a csv file to the AWS DynamoDB. You may modify the relevant parts inside `importCSV.js` to fit your needs. 

To run the project, `cd` to the root directory, do `npm install` then `npm start`. If you haven't set up the local AWS development environment before, first install the [AWS CLI tool](https://aws.amazon.com/cli/), then configure AWS access keys with `aws configure` before running this project.


# Important Notice Before Using this Project

This is not a reliable replacement of AWS's own (paid) data import service **Data Pipeline**, mainly because of DynamoDB's provisioned throughput limitation. It will throttle any read / write requests to the database once it hits the maximum capacity you set up in the table's **Capacity** tab (because this is how AWS bills DynamoDB usage). What's annoying about this is AWS won't even report an error back to the requester if a request is throttled, therefore the end result can only be checked on the cloud side, which means that **there's no way for this project alone to safely and efficiently determine if all the data are successfully put to the database**.

It's recommended that users of this project double check the total number of items put to the database against the number of valid items processed by the script (displayed at the end of execution). If there's a mismatch, check the **Metrics** tab for this table on the DynamoDB web console. The **Throttled write requests** diagram will show the number of failed write requests over time, and the **Write capacity** diagram will be a good reference for adjusting minimum write capacity units (temporarily) in the **Capacity** tab. __Do not rely solely on auto scaling to scale up the provisioned resources dynamically for this job. Scaling up will take some time, and DynamoDB will still throttle requests if insufficient resources are currently provisioned.__ When everything is set up, just rerun the project (no need to delete already-imported data). Occasionally I find it necessary to rerun the script a few times more before the dataset is fully written to the database.

An additional note: depending on the size of the raw dataset, this project may consume a large amount of system memory during data processing. Make sure you have sufficient free memory before using the script, or rewrite it to store intermediate config data (specifically the `jobStack` mechanism) on disk instead.


# Some Helpful Online Resources for Understanding DynamoDB

* [DynamoDB shortcomings (and our work arounds)](https://www.dailycred.com/article/dynamodb-shortcomings-and-work-arounds)

    Ignoring the Dynamonito promotion part, this article makes some good points on DynamoDB's shortcomings. I'll include this here as a reference in case the team plans to perform complex data analysis on the current database again in the future.


# Additional Notes

* The scripts inside the /obsolete directory are my initial attempt to put all data into a single parameter file for `batch-write-item` from the `aws-cli` tool. AWS limits the total number of requests inside a single batch write call to just [25](http://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/DynamoDB.html#batchWriteItem-property), which makes the initial method totally useless for putting more than 25 items at once to DynamoDB. Nonetheless, the `DynamoDB_Management.cmd` script is still useful for fast creating / deleting / reviewing online tables during development phase.
