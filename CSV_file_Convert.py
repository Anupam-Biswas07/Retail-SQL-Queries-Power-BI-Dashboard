import pandas as pd

#load the csv file
df = pd.read_csv(r'C:\Users\Anupa\OneDrive\Desktop\Sales_Data.csv', header=None)



# Number of rows block (12 rows)
block_size = 12
final_records = []

# loop through the dataset in chunks of 'block_size'
for start in range(0, len(df), block_size):
    block = df.iloc[start:start+block_size]

# get field name from the first column
field_names = block.iloc[:, 0].values

#loop through each column after the first one (actual data)
for col in block.columns[1:]:
   record = block[col].values
   record = dict(zip(field_names, record))
   final_records.append(record)

# convert to dataframe
final_df = pd.DataFrame(final_records)

#convert sale data from excel serialto date time
final_df["Sale_Date"] = pd.to_datetime(final_df["Sale_Date"].astype(int), origin='1899-12-30', unit='D')

#save cleand csv
final_df.to_csv("Final_sales_data.csv", index=False)

#save final file 

print("Conversion complete. cleand file saved as 'Final_sales_data.csv'")


