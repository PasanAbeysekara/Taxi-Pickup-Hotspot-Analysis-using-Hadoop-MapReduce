import pandas as pd

# --- Configuration ---
parquet_file_path = '../yellow_tripdata_2016-01.parquet' 
lookup_csv_path = '../taxi_zone_lookup.csv'         

def explore_parquet_data(file_path):
    print(f"\n--- Exploring Parquet File: {file_path} ---")
    try:
        df = pd.read_parquet(file_path)
    except FileNotFoundError:
        print(f"Error: Parquet file not found at {file_path}")
        return None
    except Exception as e:
        print(f"Error reading Parquet file: {e}")
        return None

    print("\n1. Basic Information:")
    print(f"Shape (rows, columns): {df.shape}")
    print("\nFirst 5 rows:")
    print(df.head())
    print("\nColumn Data Types and Non-Null Counts:")
    df.info(verbose=True, show_counts=True)

    print("\n2. Null Value Analysis:")
    null_counts = df.isnull().sum()
    null_percentages = (null_counts / len(df)) * 100
    null_summary = pd.DataFrame({'Null Count': null_counts, 'Null Percentage (%)': null_percentages})
    print(null_summary[null_summary['Null Count'] > 0].sort_values(by='Null Count', ascending=False))

    print("\n3. Descriptive Statistics (Numerical Columns):")
    print(df.describe())

    print("\n4. Descriptive Statistics (Object/Categorical Columns):")
    
    print(df.describe(include=['object', 'datetime64']))

    print("\n5. Specific Columns of Interest for MapReduce (PULocationID):")
    if 'PULocationID' in df.columns:
        print(f"\n--- PULocationID Analysis ---")
        print(f"Is PULocationID unique? {df['PULocationID'].is_unique}")
        print(f"Number of unique PULocationIDs: {df['PULocationID'].nunique()}")
        print(f"Nulls in PULocationID: {df['PULocationID'].isnull().sum()}")
        print(f"Min PULocationID: {df['PULocationID'].min()}")
        print(f"Max PULocationID: {df['PULocationID'].max()}")
        print("\nTop 10 most frequent PULocationIDs:")
        print(df['PULocationID'].value_counts().head(10))
        invalid_pulocations = df[df['PULocationID'] <= 0]['PULocationID'].count()
        print(f"Count of PULocationIDs <= 0: {invalid_pulocations}")
    else:
        print("PULocationID column not found!")

   
    print("\n6. Datetime Column Range (tpep_pickup_datetime):")
    if 'tpep_pickup_datetime' in df.columns:
        print(f"\n--- tpep_pickup_datetime Analysis ---")
        if pd.api.types.is_datetime64_any_dtype(df['tpep_pickup_datetime']):
            print(f"Min pickup datetime: {df['tpep_pickup_datetime'].min()}")
            print(f"Max pickup datetime: {df['tpep_pickup_datetime'].max()}")
        else:
            print("tpep_pickup_datetime is not a datetime type. Consider conversion.")
    else:
        print("tpep_pickup_datetime column not found!")

    print("\n7. Check 'congestion_surcharge' and 'airport_fee' (problematic object types):")
    if 'congestion_surcharge' in df.columns:
        print("\nValue counts for 'congestion_surcharge':")
        print(df['congestion_surcharge'].value_counts(dropna=False))
    if 'airport_fee' in df.columns:
        print("\nValue counts for 'airport_fee':")
        print(df['airport_fee'].value_counts(dropna=False))

    return df


def explore_lookup_csv_data(file_path):
    print(f"\n--- Exploring CSV Lookup File: {file_path} ---")
    try:
        df_lookup = pd.read_csv(file_path)
    except FileNotFoundError:
        print(f"Error: CSV file not found at {file_path}")
        return None
    except Exception as e:
        print(f"Error reading CSV file: {e}")
        return None

    print("\n1. Basic Information:")
    print(f"Shape (rows, columns): {df_lookup.shape}")
    print("\nFirst 5 rows:")
    print(df_lookup.head())
    print("\nColumn Data Types and Non-Null Counts:")
    df_lookup.info(verbose=True, show_counts=True)

    print("\n2. Null Value Analysis:")
    null_counts = df_lookup.isnull().sum()
    null_percentages = (null_counts / len(df_lookup)) * 100
    null_summary = pd.DataFrame({'Null Count': null_counts, 'Null Percentage (%)': null_percentages})
    print(null_summary[null_summary['Null Count'] > 0].sort_values(by='Null Count', ascending=False))

    print("\n3. Specific Columns of Interest (LocationID, Borough, Zone):")
    if 'LocationID' in df_lookup.columns:
        print(f"\n--- LocationID Analysis (Lookup Table) ---")
        print(f"Is LocationID unique? {df_lookup['LocationID'].is_unique}") # Should be True
        if not df_lookup['LocationID'].is_unique:
            print(f"DUPLICATE LocationIDs found: {df_lookup[df_lookup.duplicated(subset=['LocationID'], keep=False)]}")
        print(f"Number of unique LocationIDs: {df_lookup['LocationID'].nunique()}")
        print(f"Nulls in LocationID: {df_lookup['LocationID'].isnull().sum()}")
        print(f"Min LocationID: {df_lookup['LocationID'].min()}")
        print(f"Max LocationID: {df_lookup['LocationID'].max()}")
        if not pd.api.types.is_numeric_dtype(df_lookup['LocationID']):
            print("WARNING: LocationID in lookup table is not numeric! This will cause issues with joins.")
    else:
        print("LocationID column not found in lookup table!")

    if 'Borough' in df_lookup.columns:
        print("\nBorough value counts:")
        print(df_lookup['Borough'].value_counts(dropna=False))

    if 'Zone' in df_lookup.columns:
        print("\nZone value counts (Top 10):")
        print(df_lookup['Zone'].value_counts(dropna=False).head(10))
        print(f"Number of unique Zones: {df_lookup['Zone'].nunique()}")

    return df_lookup

def compare_ids(trip_df, lookup_df):
    if trip_df is None or lookup_df is None:
        print("\nSkipping ID comparison due to earlier data loading errors.")
        return
    
    print("\n--- Comparing PULocationIDs from Trip Data with LocationIDs in Lookup Table ---")
    
    if 'PULocationID' not in trip_df.columns or 'LocationID' not in lookup_df.columns:
        print("Required ID columns not found in one or both dataframes.")
        return

    trip_pu_ids = set(trip_df['PULocationID'].dropna().unique())
    lookup_ids = set(lookup_df['LocationID'].dropna().unique())

    print(f"Number of unique PULocationIDs in trip data: {len(trip_pu_ids)}")
    print(f"Number of unique LocationIDs in lookup table: {len(lookup_ids)}")

    ids_in_trip_not_in_lookup = trip_pu_ids - lookup_ids
    if ids_in_trip_not_in_lookup:
        print(f"\nWARNING: {len(ids_in_trip_not_in_lookup)} PULocationIDs found in trip data but NOT in lookup table.")
        print(f"Examples: {list(ids_in_trip_not_in_lookup)[:20]}")
    else:
        print("\nAll PULocationIDs from trip data are present in the lookup table's LocationIDs (based on unique values).")

    ids_in_lookup_not_in_trip = lookup_ids - trip_pu_ids
    if ids_in_lookup_not_in_trip:
        print(f"\nINFO: {len(ids_in_lookup_not_in_trip)} LocationIDs found in lookup table but NOT as PULocationIDs in this trip data sample.")
        print(f"Examples: {list(ids_in_lookup_not_in_trip)[:20]}")
    else:
        print("\nAll LocationIDs from lookup table are used as PULocationIDs in this trip data sample (based on unique values).")


# --- Run Exploration ---
trip_df = explore_parquet_data(parquet_file_path)
lookup_df = explore_lookup_csv_data(lookup_csv_path)
compare_ids(trip_df, lookup_df)

print("\n--- Exploration Complete ---")
