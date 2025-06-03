package com.nyctaxi;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;

public class PickupLocationCombiner extends Reducer<IntWritable, IntWritable, IntWritable, IntWritable> {
    private IntWritable sumWritable = new IntWritable();

    @Override
    protected void reduce(IntWritable key, Iterable<IntWritable> values, Context context)
            throws IOException, InterruptedException {
        int sum = 0;
        for (IntWritable val : values) {
            sum += val.get();
        }
        sumWritable.set(sum);
        context.write(key, sumWritable); // Output: (PULocationID, partial_sum)
    }
}
