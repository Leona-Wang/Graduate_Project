import 'package:flutter/material.dart';

import 'package:flutter_frontend/config.dart';
import 'dart:convert';

import 'charity_event_detail_page.dart';
import '../../api_client.dart';

class CharityEventListPage extends StatefulWidget {
  const CharityEventListPage({super.key});

  State<CharityEventListPage> createState() => CharityEventListState();
}

//活動類型
class CharityEvent {
  final int id;
  final String title;
  final String type;
  final String location;
  final DateTime date;
  final bool online; // ← 新增：線上活動

  CharityEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.date,
    required this.online, // ← 新增
  });

  factory CharityEvent.fromJson(Map<String, dynamic> json) {
    return CharityEvent(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      location: json['location'],
      date: DateTime.parse(json['date']),
      online: (json['online'] ?? false) == true, // ← 新增
    );
  }
}

class CharityEventListState extends State<CharityEventListPage> {
  final TextEditingController _searchController = TextEditingController();
  String? selectedType;
  String? selectedLocation;
  String? selectedTime;

  List<CharityEvent> events = [];
  //頁面切換
  bool isLoading = false;
  int currentPage = 1;
  int totalPage = 1;
  final int pageSize = 0;
  //篩選器
  bool sortAscending = true;
  bool? filterOnline; // ← 新增：null=全部, true=線上, false=線下

  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    setState(() => isLoading = true);

    final uriData = Uri.parse(ApiPath.charityEventList).replace(
      queryParameters: {
        'page': currentPage.toString(),
        if (selectedType != null && selectedType!.isNotEmpty)
          'eventType': selectedType!,
        if (selectedLocation != null && selectedLocation!.isNotEmpty)
          'location': selectedLocation!,
        if (selectedTime != null && selectedTime!.isNotEmpty)
          'time': selectedTime,
        if (_searchController.text.isNotEmpty) 'search': _searchController.text,
        if (filterOnline != null) 'online': filterOnline!.toString(), // ← 新增
        'ordering': sortAscending ? 'date' : '-date',
      },
    );

    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final response = await apiClient.get(uriData.toString());

      print(response.statusCode);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List results = json['results'];

        setState(() {
          events = results.map((e) => CharityEvent.fromJson(e)).toList();
          totalPage = (json['count'] / pageSize).ceil();
          isLoading = false;
        });
      } else {
        throw Exception('載入活動失敗');
      }
    } catch (e) {
      print('API錯誤: $e');
      setState(() => isLoading = false);
    }
  }

  //跳出活動詳情頁控制器
  void _toDetail(CharityEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CharityEventDetailPage(event: event),
      ),
    );
  }

  //主架構，其他區域分開寫
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('活動清單')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildFilters(),
            buildSearchAndSort(),
            const SizedBox(height: 8),
            Expanded(child: buildEventList()),
            buildPagination(),
          ],
        ),
      ),
    );
  }

  //建立篩選器
  Widget buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          //篩選活動類型
          buildDropdown(
            '選擇活動類型',
            selectedType,
            [
              '所有類型',
              '綜合性服務',
              '兒童青少年福利',
              '婦女福利',
              '老人福利',
              '身心障礙福利',
              '家庭福利',
              '健康醫療',
              '心理衛生',
              '社區規劃(營造)',
              '環境保護',
              '國際合作交流',
              '教育與科學',
              '文化藝術',
              '人權和平',
              '消費者保護',
              '性別平等',
              '政府單位',
              '動物保護',
            ],
            (val) => setState(() {
              selectedType = val;
              currentPage = 1;
              fetchEvents();
            }),
          ),
          const SizedBox(width: 12),

          //篩選地點
          buildDropdown(
            '選擇地點',
            selectedLocation,
            [
              '所有地點',
              '台北市',
              '新北市',
              '基隆市',
              '桃園市',
              '新竹市',
              '新竹縣',
              '苗栗縣',
              '南投縣',
              '台中市',
              '彰化縣',
              '雲林縣',
              '嘉義市',
              '嘉義縣',
              '台南市',
              '高雄市',
              '屏東縣',
              '宜蘭縣',
              '花蓮縣',
              '台東縣',
              '澎湖縣',
              '金門縣',
              '連江縣',
              '其他地區',
            ],
            (val) => setState(() {
              selectedLocation = val;
              currentPage = 1;
              fetchEvents();
            }),
          ),
          const SizedBox(width: 12),

          //篩選時間
          buildDropdown(
            '選擇時間段',
            selectedTime,
            ['三天內', '一周內', '一個月內', '三個月內', '常駐'],
            (val) => setState(() {
              selectedTime = val;
              currentPage = 1;
              fetchEvents();
            }),
          ),
          const SizedBox(width: 12),

          //線上/線下篩選
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('全部'),
                selected: filterOnline == null,
                onSelected: (_) {
                  setState(() {
                    filterOnline = null;
                    currentPage = 1;
                    fetchEvents();
                  });
                },
              ),
              ChoiceChip(
                label: const Text('線上'),
                selected: filterOnline == true,
                onSelected: (_) {
                  setState(() {
                    filterOnline = true;
                    currentPage = 1;
                    fetchEvents();
                  });
                },
              ),
              ChoiceChip(
                label: const Text('線下'),
                selected: filterOnline == false,
                onSelected: (_) {
                  setState(() {
                    filterOnline = false;
                    currentPage = 1;
                    fetchEvents();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  //建立下拉式選單
  Widget buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return SizedBox(
      width: 140,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label),
        value: value,
        items:
            items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
        onChanged: onChanged,
      ),
    );
  }

  //搜尋與排序
  Widget buildSearchAndSort() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: '搜尋活動',
              prefixIcon: Icon(Icons.search_outlined),
              border: OutlineInputBorder(),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            currentPage = 1;
                            fetchEvents();
                          });
                        },
                      )
                      : null,
            ),
            onChanged: (_) {
              setState(() {});
            },
            onSubmitted: (_) => fetchEvents(),
          ),
        ),
        IconButton(
          icon: Icon(sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
          onPressed: () {
            setState(() {
              sortAscending = !sortAscending;
              fetchEvents();
            });
          },
        ),
      ],
    );
  }

  //活動卡
  Widget buildEventList() {
    if (isLoading) return Center(child: CircularProgressIndicator());

    // 前端保底過濾（就算後端沒處理 online query）
    final visible =
        events.where((e) {
          if (filterOnline == null) return true;
          return e.online == filterOnline;
        }).toList();

    if (visible.isEmpty) return Center(child: Text('找不到該活動'));

    return ListView.builder(
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final event = visible[index];
        return Card(
          child: ListTile(
            title: Text(event.title),
            subtitle: Text(
              event.online
                  ? '線上活動 | ${event.date.toLocal().toString().split(" ")[0]}'
                  : '${event.location} | ${event.date.toLocal().toString().split(" ")[0]}',
            ),
            trailing: TextButton(
              onPressed: () => _toDetail(event),
              child: Text('活動詳情'),
            ),
          ),
        );
      },
    );
  }

  //頁面控制
  Widget buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed:
              currentPage > 1
                  ? () {
                    setState(() {
                      currentPage--;
                      fetchEvents();
                    });
                  }
                  : null,
          icon: Icon(Icons.arrow_back),
        ),
        Text('第 $currentPage 頁 / 共 $totalPage 頁'),
        IconButton(
          onPressed:
              currentPage < totalPage
                  ? () {
                    setState(() {
                      currentPage++;
                      fetchEvents();
                    });
                  }
                  : null,
          icon: Icon(Icons.arrow_forward),
        ),
      ],
    );
  }
}
