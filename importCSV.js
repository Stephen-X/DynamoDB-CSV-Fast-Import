/**
 * Script for fast importing the csv data into DynamoDB online. Written for the DestinationSA project.
 * 
 * ** Notice before using this script ***********
 * Temporarily set a larger number of write capacity units  (in my case the peak WCU was 18) 
 * in provisioned capacity, otherwise some write requests might be throttled. Please notice 
 * that request throttling MAY STILL happen if auto-scaling is enabled, since scaling up takes
 * time on AWS side. Make sure the minimum WCU is high enough, and double check on the cloud side to 
 * confirm that all items are put to the database. If the total number is incorrect, it might be 
 * helpful to check the write capacity metrics to determine the ideal WCU for this upload.
 * 
 * See README.md for more information.
 * 
 * FYI AWS provides a more reliable paid data import service called Data Pipeline.
 * **********************************************
 * 
 * -- CSV format ---------------------
 * longitude,latitude
 * 138.4xxxxx,-34.9xxxxx
 * ...
 * -----------------------------------
 * 
 * -- Format of data put to table -----
 * id (primary key, hashed): String,
 * agency: 'DPTI',
 * is_dynamic: 'true',
 * longitude: Number,
 * latitude: Number
 * ------------------------------------
 * 
 * My regards to Hassan Siddique for providing a good starting point:
 * https://stackoverflow.com/questions/32678325/how-to-import-bulk-data-from-csv-to-dynamodb
 * 
 * @author Stephen Tse <Stephen.Xie@sa.gov.au>
 * @version 1.0.2
 */

'use strict';

const fs = require('fs');
const csvParser = require('csv-parse');
const crypto = require('crypto');
const async = require('async');

const AWS = require('aws-sdk');
AWS.config.update({ region: 'ap-southeast-2' });
const dynamo = new AWS.DynamoDB.DocumentClient();

// ** Set up variables here ********************************
const csv_filename = 'devices.csv';
const table_name = 'Device';

// additional properties to be included
const agency = 'DPTI';
const is_dynamic = 'true';
// *********************************************************

const rs = fs.createReadStream(csv_filename);
const parser = csvParser({
    auto_parse: true,
    columns : true,
    delimiter : ','
}, function(err, data) {
    const max_reqs = 25;  // maximum put requests for one batchWrite() allowed by AWS
    let itemSet = {};  // the raw csv dataset contains duplicates; used this as a hash set to detect duplicates
    let jobStack = [];  // a stack of request parameters for batchWrites
    let itemCount = 0;  // total number of items processed
    let duplicateCount = 0;  // total number of duplicate items

    // construct job stack
    while (data.length > 0) {
        // parameter template for batchWrite()
        const params = {
            RequestItems: {
                [table_name]: []
            }
        }
        // extract 25 items from start of data, then create a new job with 25 put requests
        data.splice(0, max_reqs).forEach((item) => {
            let id = item.longitude.toString() + item.latitude.toString() + agency;
            let hashedId = crypto.createHash('md5').update(id, 'utf8').digest('hex');  // create hashed id as per requirement

            if (!itemSet[hashedId]) {  // this is a new item
                params.RequestItems[table_name].push({
                    PutRequest: {
                        Item: {  // ** Also modify item schema here **********
                            id: hashedId,
                            longitude: item.longitude,
                            latitude: item.latitude,
                            agency: agency,
                            is_dynamic: is_dynamic
                        }  // ************************************************
                    }
                });
                itemSet[hashedId] = true;  // add this item to the set
                itemCount++;
            } else {
                duplicateCount++;
                console.log(`Duplicate item found: long = ${item.longitude}, lat = ${item.latitude}; skipped.`);
            }
        });
        jobStack.push(params);  // push this job to the stack
    }

    
    let chunkNo = 0;  // number of each batchWrite operation

    // issue batchWrite() for each job in the stack; use async.js to better handle the asynchronous processing
    async.each(jobStack, (params, callback) => {
        //console.log(JSON.stringify(params), "\n");
        chunkNo++;
        dynamo.batchWrite(params, callback);
        //callback();
    }, (err) => {
        if (err) {
            console.log(`Chunk #${chunkNo} write unsuccessful: ${err.message}`);
        } else {
            console.log('\nImport operation completed! Do double check on DynamoDB for actual number of items stored.');
            console.log(`Total batchWrite requests issued: ${chunkNo}`);
            console.log(`Total valid items processed: ${itemCount}`);
            console.log(`Total number of duplicates in the raw data: ${duplicateCount}`);
        }
    });

});
rs.pipe(parser);  // pipe the file readable stream to configured csv parser
