import 'package:flutter/material.dart';

class PersonalPetDetailPage extends StatefulWidget {
  const PersonalPetDetailPage({
    super.key,
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.owned,
  });

  final String id;
  final String name;
  final String imageUrl;
  final bool owned;

  @override
  State<PersonalPetDetailPage> createState() => _PersonalPetDetailPageState();
}

class _PetDetail {
  final int intimacy; // 後端直接給親密度

  _PetDetail({required this.intimacy});
}

class _PersonalPetDetailPageState extends State<PersonalPetDetailPage> {
  late Future<_PetDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchDetail(widget.id);
  }

  // TODO: 後端 API
  Future<_PetDetail> fetchDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _PetDetail(intimacy: 78);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: FutureBuilder<_PetDetail>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 頭圖
              Hero(
                tag: 'pet:${widget.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.imageUrl,
                    height: 240,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(
                    text: widget.owned ? '已持有' : '未持有',
                    color: widget.owned ? Colors.green : Colors.grey,
                  ),
                  _chip(text: 'ID ${widget.id}', color: Colors.indigo),
                ],
              ),
              const SizedBox(height: 20),

              _infoRow(
                label: '親密度',
                valueText: d.intimacy.toString(),
                icon: Icons.favorite,
              ),

              const SizedBox(height: 28),

              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _openInventory(context),
                  icon: const Icon(Icons.inventory),
                  label: const Text("提升親密度"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 12),

              // 介紹
              const Text(
                '寵物介紹',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 1.4),
              const Text('寵物的介紹。'),
            ],
          );
        },
      ),
    );
  }

  // ===== UI helpers =====
  Widget _chip({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _infoRow({
    required String label,
    required String valueText,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(valueText, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  void _openInventory(BuildContext context) {
    // 模擬從 API 拿到的資料（未來可替換成後端回傳）
    final items = [
      {
        "name": "餅乾",
        "value": 20,
        "image": "assets/petFoods/Cookie.PNG",
        "owned": 12,
      },
      {
        "name": "蛋糕",
        "value": 20,
        "image": "assets/petFoods/Cake.PNG",
        "owned": 3,
      },
      {
        "name": "珍珠奶茶",
        "value": 20,
        "image": "assets/petFoods/Bubbletea.PNG",
        "owned": 1,
      },
      {
        "name": "布丁",
        "value": 20,
        "image": "assets/petFoods/Pudding.PNG",
        "owned": 0,
      },
      {
        "name": "雞腿",
        "value": 20,
        "image": "assets/petFoods/Getui.PNG",
        "owned": 0,
      },
      {
        "name": "太妃糖",
        "value": 20,
        "image": "assets/petFoods/Toffee.PNG",
        "owned": 0,
      },
      {
        "name": "水母",
        "value": 20,
        "image": "assets/petFoods/Jellyfish.PNG",
        "owned": 0,
      },
      {
        "name": "好吃便當",
        "value": 20,
        "image": "assets/petFoods/Bentou.PNG",
        "owned": 0,
      },
      {
        "name": "章魚燒",
        "value": 20,
        "image": "assets/petFoods/Takoyaki.PNG",
        "owned": 0,
      },
      {
        "name": "蘑菇",
        "value": 20,
        "image": "assets/petFoods/Mushroom.PNG",
        "owned": 0,
      },
    ];

    // 使用者選擇的數量
    final counts = List<int>.filled(items.length, 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            int total = 0;
            for (int i = 0; i < items.length; i++) {
              total += counts[i] * (items[i]["value"] as int);
            }

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "選擇道具提升親密度",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 200, //每格高度
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 60,
                                padding: const EdgeInsets.all(6),
                                child: Image.asset(
                                  item['image'] as String,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item["name"] as String, //之後要改成前端自己取的名字
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text("+${item["value"]} 親密度"),
                              Text(
                                "持有 ${item["owned"]}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    onPressed: () {
                                      if (counts[index] > 0) {
                                        setState(() => counts[index]--);
                                      }
                                    },
                                  ),
                                  Text("${counts[index]}"),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      // 限制不能超過持有數量
                                      if (counts[index] <
                                          (item["owned"] as int)) {
                                        setState(() => counts[index]++);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "總親密度 +$total",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed:
                              total > 0
                                  ? () {
                                    Navigator.pop(context);
                                    // 呼叫 API 消耗道具
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("確認"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
