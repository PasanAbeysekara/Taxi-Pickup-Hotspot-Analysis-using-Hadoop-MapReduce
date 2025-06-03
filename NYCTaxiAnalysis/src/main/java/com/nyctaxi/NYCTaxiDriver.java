package com.nyctaxi;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.parquet.hadoop.ParquetInputFormat;
import org.apache.parquet.hadoop.example.GroupReadSupport;


public class NYCTaxiDriver {

    public static void main(String[] args) throws Exception {
        if (args.length != 3) {
            System.err.println("Usage: NYCTaxiDriver <input path (parquet)> <output path> <zone_lookup_csv_hdfs_path>");
            System.exit(-1);
        }

        Configuration conf = new Configuration();
        Job job = Job.getInstance(conf, "NYC Taxi Pickup Count");

        job.setInputFormatClass(ParquetInputFormat.class);
        ParquetInputFormat.setReadSupportClass(job, GroupReadSupport.class);

        job.setJarByClass(NYCTaxiDriver.class);
        job.setMapperClass(PickupLocationMapper.class);

	job.setCombinerClass(PickupLocationCombiner.class);
	job.setReducerClass(PickupLocationReducer.class);

        job.setMapOutputKeyClass(IntWritable.class);
        job.setMapOutputValueClass(IntWritable.class);

        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);

        FileInputFormat.addInputPath(job, new Path(args[0])); // Parquet data HDFS path
        FileOutputFormat.setOutputPath(job, new Path(args[1])); // Output HDFS path

        // Add taxi_zone_lookup.csv to DistributedCache
        // The path provided (args[2]) should be its HDFS path
        job.addCacheFile(new Path(args[2]).toUri());
        
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
