import requests
from bs4 import BeautifulSoup
import csv

with open('orgidList.csv', 'w', newline='', encoding='utf-8') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(['orgid']) # 寫欄位名稱（只要一次）

    for i in range(1, 499):
        url = f'https://www.npo.org.tw/npolist.aspx?nowPage={i}&tid=147'
        response = requests.get(url)
        response.encoding = response.apparent_encoding
        html = response.text
        soup = BeautifulSoup(html, 'html.parser')

        tdList = soup.find_all('td', attrs={'data-th': '機構代碼'})

        for td in tdList:
            writer.writerow([td.text.strip()])
        print(f"page {i} finish")
"""
# 只取這個區塊
introDiv = soup.find('div', class_='intro_list')

# 所有 h4
h4List = introDiv.find_all('h4')

result = []

for h4 in h4List:
    textParts = []

    # 取所有文字（包含<br/>會被轉成分段文字）
    for item in h4.stripped_strings:
        textParts.append(item)

    # 嘗試找出「冒號」的分割
    if len(textParts) >= 2:
        # 一般情況： ['機構代碼：', '7770']
        key, *value = textParts
        # 去掉冒號
        key = key.split('：')[0].strip()
        value = ' '.join(value).strip()
    else:
        # 可能是整段都在一起
        line = textParts[0]
        if '：' in line:
            key, value = line.split('：', 1)
            key = key.strip()
            value = value.strip()
        else:
            key = ''
            value = line.strip()

    result.append((key, value))

# 顯示結果
for key, value in result:
    print(f'{key}')
"""
