package com.nyctaxi;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.parquet.example.data.Group;
import org.apache.parquet.schema.Type; 

import java.io.IOException;

public class PickupLocationMapper extends Mapper<LongWritable, Group, IntWritable, IntWritable> {

    private final static IntWritable one = new IntWritable(1);
    private IntWritable locationIdWritable = new IntWritable();
    private final String PULOCATION_ID_FIELD = "PULocationID";

    @Override
    protected void map(LongWritable key, Group value, Context context)
            throws IOException, InterruptedException {
        
        if (value == null) {
            context.getCounter("MapperErrors", "NullInputGroupRecord").increment(1);
            System.err.println("Mapper received a null Group record for key: " + key.toString());
            return; 
        }

        try {
            if (!value.getType().containsField(PULOCATION_ID_FIELD)) {
                context.getCounter("MapperErrors", "Missing_PULocationID_Field_In_Record_Schema").increment(1);
                System.err.println("PULocationID field missing in schema for record: " + value.toString());
                return; 
            }

            Type fieldType = value.getType().getType(PULOCATION_ID_FIELD);
            if (fieldType.asPrimitiveType().getPrimitiveTypeName() != org.apache.parquet.schema.PrimitiveType.PrimitiveTypeName.INT64 &&
                fieldType.asPrimitiveType().getPrimitiveTypeName() != org.apache.parquet.schema.PrimitiveType.PrimitiveTypeName.INT32) {
                context.getCounter("MapperErrors", "PULocationID_Not_IntegerType").increment(1);
                System.err.println("PULocationID field is not of expected integer type. Actual type: " + 
                                   fieldType.asPrimitiveType().getPrimitiveTypeName() + " for record: " + value.toString());
                return; 
            }

            if (value.getFieldRepetitionCount(PULOCATION_ID_FIELD) > 0) {
                int puLocationID;
                if (fieldType.asPrimitiveType().getPrimitiveTypeName() == org.apache.parquet.schema.PrimitiveType.PrimitiveTypeName.INT64) {
                    puLocationID = (int) value.getLong(PULOCATION_ID_FIELD, 0); 
                } else { 
                    puLocationID = value.getInteger(PULOCATION_ID_FIELD, 0);
                }
                
                if (puLocationID > 0) { 
                    locationIdWritable.set(puLocationID);
                    context.write(locationIdWritable, one); 
                } else {
                    context.getCounter("MapperInfo", "InvalidPULocationID_Value_NonPositive").increment(1);
                }
            } else {
                context.getCounter("MapperInfo", "PULocationID_Field_PresentButNullOrEmpty").increment(1);
                System.err.println("PULocationID field present in schema but has no value (null/empty) for record: " + value.toString());
            }

        } catch (java.lang.RuntimeException e) { 
            context.getCounter("MapperErrors", "ParquetProcessingRuntimeException").increment(1);
            System.err.println("Runtime exception processing Parquet record in Mapper. Record: " + (value != null ? value.toString() : "null") + " Error: " + e.getMessage());
            e.printStackTrace(System.err);
        }
    }
}
