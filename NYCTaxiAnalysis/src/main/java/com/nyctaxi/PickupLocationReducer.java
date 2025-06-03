package com.nyctaxi;

import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.net.URI;
import java.util.HashMap;
import java.util.Map;

public class PickupLocationReducer extends Reducer<IntWritable, IntWritable, Text, IntWritable> {

    private Map<Integer, String[]> zoneLookup = new HashMap<>(); // LocationID -> {Borough, Zone}
    private Text outputKey = new Text();
    private IntWritable result = new IntWritable();
    private final String DEFAULT_BOROUGH = "Unknown Borough";
    private final String DEFAULT_ZONE = "Unknown Zone";

    @Override
    protected void setup(Context context) throws IOException, InterruptedException {
        URI[] cacheFiles = context.getCacheFiles();
        if (cacheFiles != null && cacheFiles.length > 0) {
            boolean loaded = false;
            for (URI cacheFile : cacheFiles) {
                if (cacheFile.getPath().endsWith("taxi_zone_lookup.csv")) {
                    loadZoneLookupData(new Path(cacheFile).getName(), context); // Pass only the file name
                    loaded = true;
                    break;
                }
            }
            if (!loaded) {
                 throw new IOException("Zone lookup file 'taxi_zone_lookup.csv' not found in DistributedCache URIs.");
            }
        } else {
            throw new IOException("No files found in DistributedCache.");
        }

        if (zoneLookup.isEmpty()){
            context.getCounter("ReducerSetup", "ZoneLookupEmpty").increment(1);
            System.err.println("Warning: Zone lookup data is empty after attempting to load.");
        }
    }

    private void loadZoneLookupData(String localFileName, Context context) throws IOException {
        String line;
        // Files from DistributedCache are on the local file system of the task node
        try (BufferedReader reader = new BufferedReader(new FileReader(localFileName))) {
            String header = reader.readLine();
            if (header == null) {
                context.getCounter("LookupParseErrors", "EmptyFile").increment(1);
                System.err.println("Warning: Zone lookup file " + localFileName + " is empty or has no header.");
                return;
            }

            int lineNumber = 1; // For logging
            while ((line = reader.readLine()) != null) {
                lineNumber++;
                String[] parts = line.split(",", -1); 

                if (parts.length >= 3) { 
                    try {
                        int locationID = Integer.parseInt(parts[0].replace("\"", "").trim());
                        
                        String borough = (parts[1] != null && !parts[1].replace("\"", "").trim().isEmpty()) ?
                                         parts[1].replace("\"", "").trim() : DEFAULT_BOROUGH;
                        String zone =    (parts[2] != null && !parts[2].replace("\"", "").trim().isEmpty()) ?
                                         parts[2].replace("\"", "").trim() : DEFAULT_ZONE;
                        
                        zoneLookup.put(locationID, new String[]{borough, zone});

                    } catch (NumberFormatException e) {
                        context.getCounter("LookupParseErrors", "MalformedLocationID").increment(1);
                        System.err.println("Skipping malformed line in lookup table (LocationID parse error) at line " + lineNumber + ": " + line + " - " + e.getMessage());
                    } catch (ArrayIndexOutOfBoundsException e) {
                        context.getCounter("LookupParseErrors", "MissingFields").increment(1);
                        System.err.println("Skipping malformed line in lookup table (Missing fields) at line " + lineNumber + ": " + line + " - " + e.getMessage());
                    }
                } else {
                    context.getCounter("LookupParseErrors", "TooFewFields").increment(1);
                    System.err.println("Skipping malformed line in lookup table (Too few fields) at line " + lineNumber + ": " + line);
                }
            }
        } catch (IOException e) {
            context.getCounter("ReducerSetup", "ZoneLookupFileReadError").increment(1);
            System.err.println("Error reading zone lookup file '" + localFileName + "': " + e.getMessage());
            throw new IOException("Error reading zone lookup file: " + localFileName, e);
        }
        context.getCounter("ReducerSetup", "ZoneLookupEntriesLoaded").setValue(zoneLookup.size());
    }

    @Override
    protected void reduce(IntWritable key, Iterable<IntWritable> values, Context context)
            throws IOException, InterruptedException {
        int sum = 0;
        for (IntWritable val : values) {
            sum += val.get();
        }

        int locationID = key.get();
        String[] lookupInfo = zoneLookup.get(locationID);
        String zoneNameWithBorough;

        if (lookupInfo != null) {
            String borough = lookupInfo[0]; // Should be DEFAULT_BOROUGH if originally null
            String zone = lookupInfo[1];    // Should be DEFAULT_ZONE if originally null
            zoneNameWithBorough = zone + " (" + borough + ")";
        } else {
            zoneNameWithBorough = DEFAULT_ZONE + " ID:" + locationID + " (" + DEFAULT_BOROUGH + ")";
            context.getCounter("LookupErrors", "IDNotFoundInCache").increment(1);
        }
        
        outputKey.set(zoneNameWithBorough);
        result.set(sum);
        context.write(outputKey, result);
    }
}
