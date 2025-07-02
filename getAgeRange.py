import pandas as pd
import re


def containsChinese(text):
    if pd.isna(text):
        return False
    return bool(re.search(r'[\u4e00-\u9fff]', str(text)))


def cleanPart(part):
    if pd.isna(part):
        return ""
    part = part.strip()
    if containsChinese(part):
        return part # 保留中文原樣
    if part.isdigit():
        return "" if int(part) == 0 else part
    return ""


# 讀入檔案
df = pd.read_csv('ageRange.csv')

# 新增欄位
df['left'] = ""
df['right'] = ""
hasChineseIds = []

for idx, row in df.iterrows():
    idVal = row['code']
    content = str(row['ageRange']) if not pd.isna(row['ageRange']) else ""

    # 檢查是否含中文
    if containsChinese(content):
        hasChineseIds.append(idVal)

    # 拆 ~
    if "~" in content:
        leftPart, rightPart = content.split("~", 1)
    else:
        leftPart, rightPart = content, ""

    # 清洗
    leftClean = cleanPart(leftPart)
    rightClean = cleanPart(rightPart)

    df.at[idx, 'left'] = leftClean
    df.at[idx, 'right'] = rightClean

# 輸出結果 CSV
df[['code', 'left', 'right']].to_csv('output.csv', index=False)

# 印出需要手動處理的ID
print("含中文的 id：")
for idVal in hasChineseIds:
    print(idVal)
