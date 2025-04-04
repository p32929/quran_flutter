import json
import os
import shutil
from pathlib import Path

# Paths
input_dir = "./assets/data"  # Directory containing individual surah JSON files
output_dir = "./assets/hive_data"  # Directory to store the processed data

# Create output directory if it doesn't exist
Path(output_dir).mkdir(parents=True, exist_ok=True)

# Process all surah files
def process_surah_files():
    print("Starting JSON processing...")
    all_surahs_data = {}
    
    # Get all JSON files
    files = [f for f in os.listdir(input_dir) if f.startswith('surah_') and f.endswith('.json')]
    files.sort(key=lambda x: int(x.split('_')[1].split('.')[0]))  # Sort by surah number
    
    total_files = len(files)
    print(f"Found {total_files} surah files to process")
    
    # Process each file
    for i, filename in enumerate(files):
        surah_num = int(filename.split('_')[1].split('.')[0])
        file_path = os.path.join(input_dir, filename)
        
        print(f"Processing {filename} ({i+1}/{total_files})...")
        
        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                surah_data = json.load(file)
                
                # Optimize the data structure for quicker access
                optimized_data = {
                    'surahNo': surah_data.get('surahNo', surah_num),
                    'surahName': surah_data.get('surahName', ''),
                    'surahNameArabic': surah_data.get('surahNameArabic', ''),
                    'surahNameArabicLong': surah_data.get('surahNameArabicLong', ''),
                    'surahNameTranslation': surah_data.get('surahNameTranslation', ''),
                    'revelationPlace': surah_data.get('revelationPlace', ''),
                    'totalAyah': surah_data.get('totalAyah', 0),
                    'ayahs': []
                }
                
                # Extract ayahs if available
                if 'ayahs' in surah_data and isinstance(surah_data['ayahs'], list):
                    for ayah in surah_data['ayahs']:
                        optimized_data['ayahs'].append({
                            'number': ayah.get('number', 0),
                            'arabic': ayah.get('arabic', ''),
                            'english': ayah.get('english', ''),
                            'bengali': ayah.get('bengali', '')
                        })
                else:
                    # If no ayahs array, try to build it from individual translation arrays
                    arabic_list = surah_data.get('arabic1', [])
                    english_list = surah_data.get('english', [])
                    bengali_list = surah_data.get('bengali', [])
                    
                    max_len = max(len(arabic_list), len(english_list), len(bengali_list))
                    
                    for i in range(max_len):
                        ayah = {
                            'number': i + 1,
                            'arabic': arabic_list[i] if i < len(arabic_list) else '',
                            'english': english_list[i] if i < len(english_list) else '',
                            'bengali': bengali_list[i] if i < len(bengali_list) else ''
                        }
                        optimized_data['ayahs'].append(ayah)
                
                # Add to our collection
                all_surahs_data[str(surah_num)] = optimized_data
                
        except Exception as e:
            print(f"Error processing {filename}: {e}")
    
    return all_surahs_data

# Create an index file with metadata about all surahs
def create_surah_index():
    print("Creating surah index...")
    surahs_index = []
    
    try:
        # Look for a surahs.json file in the input directory
        index_path = os.path.join(input_dir, 'surahs.json')
        if os.path.exists(index_path):
            with open(index_path, 'r', encoding='utf-8') as file:
                surahs_data = json.load(file)
                for i, surah in enumerate(surahs_data):
                    # Add the surah number which might be missing
                    surah_data = dict(surah)
                    surah_data['number'] = i + 1  # 1-indexed
                    surahs_index.append(surah_data)
        else:
            # If no index file exists, build a basic index from the surah files
            files = [f for f in os.listdir(input_dir) if f.startswith('surah_') and f.endswith('.json')]
            files.sort(key=lambda x: int(x.split('_')[1].split('.')[0]))
            
            for filename in files:
                surah_num = int(filename.split('_')[1].split('.')[0])
                file_path = os.path.join(input_dir, filename)
                
                with open(file_path, 'r', encoding='utf-8') as file:
                    surah_data = json.load(file)
                    surahs_index.append({
                        'number': surah_num,
                        'name': surah_data.get('surahName', ''),
                        'nameArabic': surah_data.get('surahNameArabic', ''),
                        'nameArabicLong': surah_data.get('surahNameArabicLong', ''),
                        'nameTranslation': surah_data.get('surahNameTranslation', ''),
                        'totalAyah': surah_data.get('totalAyah', 0),
                        'revelationPlace': surah_data.get('revelationPlace', '')
                    })
    except Exception as e:
        print(f"Error creating index: {e}")
    
    return surahs_index

# Main execution
if __name__ == "__main__":
    # Process surah data
    all_surahs_data = process_surah_files()
    
    # Create surah index
    surahs_index = create_surah_index()
    
    # Write the optimized data to output files
    with open(os.path.join(output_dir, 'quran_data.json'), 'w', encoding='utf-8') as f:
        json.dump(all_surahs_data, f, ensure_ascii=False)
    
    with open(os.path.join(output_dir, 'surahs_index.json'), 'w', encoding='utf-8') as f:
        json.dump(surahs_index, f, ensure_ascii=False)
    
    print(f"\nProcessing complete! Files saved to {output_dir}")
    print(f"- quran_data.json: Contains all surah details")
    print(f"- surahs_index.json: Contains index of all surahs")