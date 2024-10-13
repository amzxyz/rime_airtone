import os
from tqdm import tqdm  # 引入tqdm库用于显示进度条
from pypinyin import pinyin, lazy_pinyin, load_phrases_dict, load_single_dict, Style

# 加载自定义拼音的函数，支持自动判断单字和词组
def load_custom_pinyin_from_directory(directory):
    single_dict = {}
    phrases_dict = {}

    if not os.path.exists(directory):
        print(f"目录 '{directory}' 不存在。")
        return

    for file_name in os.listdir(directory):
        file_path = os.path.join(directory, file_name)
        if os.path.isfile(file_path) and (file_name.endswith('.txt') or file_name.endswith('.yaml')):
            print(f"正在加载文件: {file_path}")
            with open(file_path, 'r', encoding='utf-8') as f:
                for line in f:
                    parts = line.strip().split('\t')
                    if len(parts) < 2:
                        continue  # 忽略无效行

                    word = parts[0]  # 词组或单字
                    pinyins = parts[1].split(' ')  # 拼音用空格分割

                    if len(word) == 1:  # 如果是单字
                        single_dict[ord(word)] = ','.join(pinyins)
                    else:  # 如果是词组
                        phrases_dict[word] = [[p] for p in pinyins]

    if phrases_dict:
        load_phrases_dict(phrases_dict)
        print(f"已加载 {len(phrases_dict)} 个词组拼音。")

    if single_dict:
        load_single_dict(single_dict)
        print(f"已加载 {len(single_dict)} 个单字拼音。")

# 处理文件内容，按行加载
def load_words(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        return [line.strip().split('\t') for line in f]

output_table = {}

def replace_pinyin(words, output_table):
    for word_info in words:
        if word_info[0].startswith('#'):
            continue

        word = word_info[0]  # 单字或词组
        pinyin_list = pinyin(word, v_to_u=True, heteronym=True, errors='ignore')  # 获取拼音列表

        if len(word_info) > 1:
            current_pinyin = word_info[1] if len(word_info) > 1 else ''
            
            if current_pinyin.isdigit():
                pinyin_variants = [py[0] for py in pinyin_list]
                word_info[1] = ' '.join(pinyin_variants)
                if len(word_info) < 3:
                    word_info.append(current_pinyin)
                else:
                    word_info[2] = current_pinyin
                continue

            new_segments = []
            if pinyin_list:
                if len(word) == 1:  # 单字处理
                    pinyin_variants = [py for sublist in pinyin_list for py in sublist]
                    recognition_codes = [py.replace('ā', 'a').replace('á', 'a').replace('ǎ', 'a').replace('à', 'a')
                                         .replace('ē', 'e').replace('é', 'e').replace('ě', 'e').replace('è', 'e')
                                         .replace('ī', 'i').replace('í', 'i').replace('ǐ', 'i').replace('ì', 'i')
                                         .replace('ō', 'o').replace('ó', 'o').replace('ǒ', 'o').replace('ò', 'o')
                                         .replace('ū', 'u').replace('ú', 'u').replace('ǔ', 'u').replace('ù', 'u')
                                         .replace('ü', 'v').replace('ǖ', 'v').replace('ǘ', 'v').replace('ǚ', 'v').replace('ǜ', 'v') for py in pinyin_variants]

                    output_table[word] = {"拼音": pinyin_variants, "识别码": recognition_codes}

                    for current_segment in current_pinyin.split():
                        match_found = False
                        for idx, code in enumerate(recognition_codes):
                            if code in current_segment:
                                segment_idx = next((i for i, c in enumerate(current_segment) if c in [';', '[']), -1)
                                new_first_segment = pinyin_variants[idx] + current_segment[segment_idx:] if segment_idx != -1 else pinyin_variants[idx]
                                new_segments.append(new_first_segment)
                                match_found = True
                                break
                        if not match_found:
                            new_segments.append(current_segment)

                    word_info[1] = ' '.join(new_segments)

                elif len(word) > 1:  # 多字词组处理
                    for idx, segment in enumerate(current_pinyin.split()):
                        if idx < len(pinyin_list):
                            new_segments.append(pinyin_list[idx][0] + segment[segment.find(';'):] if ';' in segment or '[' in segment else pinyin_list[idx][0])
                        else:
                            new_segments.append(segment)
                    word_info[1] = ' '.join(new_segments)
            else:
                word_info[1] = current_pinyin

    return words

def process_files(input_directory, output_directory):
    files = [f for f in os.listdir(input_directory) if f.endswith('.txt') or f.endswith('.yaml')]
    
    for file_name in tqdm(files, desc="处理文件进度"):
        file_path = os.path.join(input_directory, file_name)
        words = load_words(file_path)
        modified_words = replace_pinyin(words, output_table)

        output_file_path = os.path.join(output_directory, file_name)
        with open(output_file_path, 'w', encoding='utf-8') as f:
            for word in modified_words:
                f.write('\t'.join(word) + '\n')

        print(f"处理完成: {output_file_path}")

# 定义输入和输出路径为相对路径
input_path = 'cn_dicts_wan'
output_path = 'new_cn_dicts'
custom_pinyin_dir = 'custom-dicts'

# 创建输出文件夹（如果不存在）
os.makedirs(output_path, exist_ok=True)

# 从指定目录加载自定义拼音
load_custom_pinyin_from_directory(custom_pinyin_dir)

# 处理输入文件并显示进度条
process_files(input_path, output_path)
