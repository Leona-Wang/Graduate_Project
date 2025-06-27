import requests
from bs4 import BeautifulSoup
import csv

columns = [
    'name', 'code', 'CEO', 'contact', 'phone', 'fax', 'website', 'email', 'address', 'founder', 'founded', 'authority',
    'type', 'mission', 'focus', 'area', 'gender', 'age', 'service'
]

# ✅ 建立對應表：中文欄位 ➜ 英文欄位
fieldMap = {
    '機構名稱': 'name',
    '機構代碼': 'code',
    '執行長': 'CEO',
    '聯絡人': 'contact',
    '電話': 'phone',
    '傳真': 'fax',
    '網址': 'website',
    '電子郵件': 'email',
    '地址': 'address',
    '創辦人': 'founder',
    '成立日期': 'founded',
    '許可機關': 'authority',
    '機構屬性': 'type',
    '成立主旨': 'mission',
    '工作重點': 'focus',
    '服務區域': 'area',
    '服務性別': 'gender',
    '服務年齡': 'age',
    '服務項目': 'service'
}

orgIdList = []
with open('orgidList.csv', newline='', encoding='utf-8') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        orgIdList.append(row['orgid'].strip())

print(f'共讀取 {len(orgIdList)} 筆 orgid')

with open('orgDetailList.csv', 'w', newline='', encoding='utf-8-sig') as csvfile:
    writer = csv.writer(csvfile, quoting=csv.QUOTE_MINIMAL)
    writer.writerow(columns) # 寫欄位名稱（一次就好）

    # ✅ 逐筆處理每個 orgid
    for orgId in orgIdList:
        print(f'正在抓取 orgid={orgId} ...')

        url = f'https://www.npo.org.tw/orgnpointroduction.aspx?tid=200&orgid={orgId}'
        try:
            response = requests.get(url, timeout=10)
            response.encoding = response.apparent_encoding
        except Exception as e:
            print(f'orgid={orgId} 發生錯誤：{e}')
            continue

        html = response.text
        soup = BeautifulSoup(html, 'html.parser')

        # ✅ 找出詳細區塊
        introDiv = soup.find('div', class_='intro_list')
        if not introDiv:
            print(f'orgid={orgId} 找不到 intro_list 區塊')
            continue

        # ✅ 解析裡面的 h4
        h4List = introDiv.find_all('h4')
        result = []

        for h4 in h4List:
            # 取出所有文字（包含 <br> 會分段）
            textParts = [s.strip() for s in h4.stripped_strings]

            if len(textParts) >= 2:
                key = textParts[0].split('：')[0].strip()
                value = ' '.join(textParts[1:]).strip()
            elif len(textParts) == 1 and '：' in textParts[0]:
                key, value = textParts[0].split('：', 1)
                key = key.strip()
                value = value.strip()
            else:
                key = ''
                value = ' '.join(textParts).strip()

            result.append((key, value))

        # ✅ 轉成欄位對應
        rowData = {col: '' for col in columns}
        for key, value in result:
            print(f"{key}:{value}")
            if key in fieldMap:
                engKey = fieldMap[key]
                rowData[engKey] = value

        # ✅ 寫進 CSV
        rowList = [rowData[col] for col in columns]
        writer.writerow(rowList)
        print(f'orgid={orgId} 結束')
