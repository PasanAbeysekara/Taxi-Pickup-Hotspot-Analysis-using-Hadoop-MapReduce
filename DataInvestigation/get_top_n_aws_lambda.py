import sys
import pandas as pd

def get_top_n_from_hadoop_output(hadoop_output_path, top_n=10):

    # ------ BEFORE RUN THIS --------
    # This assumes you run this script on a machine that can run hdfs dfs -cat
    # Or, you first download the part-r-* files locally.
    # For simplicity, let's assume the file is local after `hdfs dfs -getmerge`
    
    # Example: If you merged the output locally:
    # hdfs dfs -getmerge /user/your_username/nyctaxi_output/part-r-* local_output.txt
    # hadoop_output_path = "local_output.txt"

    # ------ To RUN THE CODE ---------
    # python get_top_n.py local_output.txt

    results = []
    try:
        with open(hadoop_output_path, 'r') as f:
            for line in f:
                parts = line.strip().split('\t')
                if len(parts) == 2:
                    zone_borough = parts[0]
                    try:
                        count = int(parts[1])
                        results.append((zone_borough, count))
                    except ValueError:
                        print(f"Skipping malformed line (count not int): {line.strip()}", file=sys.stderr)
                else:
                    print(f"Skipping malformed line (not 2 parts): {line.strip()}", file=sys.stderr)
    except FileNotFoundError:
        print(f"Error: File not found at {hadoop_output_path}", file=sys.stderr)
        return

    if not results:
        print("No data processed.")
        return

    sorted_results = sorted(results, key=lambda item: item[1], reverse=True)

    print(f"Top {top_n} Busiest Pickup Locations:")
    for i, (zone, count) in enumerate(sorted_results[:top_n]):
        print(f"{i+1}. {zone}: {count}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python get_top_n.py <path_to_hadoop_output_file>")
        sys.exit(1)
    
    hadoop_file_path = sys.argv[1]

    get_top_n_from_hadoop_output(hadoop_file_path, top_n=20)
