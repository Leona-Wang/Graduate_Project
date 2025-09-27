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

// 假的詳情資料模型（之後對接 API）
class _PetDetail {
  final int level;
  final int hp; final int hpMax;
  final int energy; final int energyMax;
  final int intimacy; // 0~100
  final List<_Item> quickItems; // 常用道具

  _PetDetail({
    required this.level,
    required this.hp,
    required this.hpMax,
    required this.energy,
    required this.energyMax,
    required this.intimacy,
    required this.quickItems,
  });
}

class _Item {
  final String id;
  final String name;
  final int count;
  _Item({required this.id, required this.name, required this.count});
}

class _PersonalPetDetailPageState extends State<PersonalPetDetailPage> {
  late Future<_PetDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchDetail(widget.id);
  }

  // TODO: 改為打後端 API：GET /pets/{id}/detail
  Future<_PetDetail> fetchDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _PetDetail(
      level: 12,
      hp: 180, hpMax: 220,
      energy: 60, energyMax: 100,
      intimacy: 78,
      quickItems: [
        _Item(id: 'food01', name: '高級飼料', count: 4),
        _Item(id: 'toy01', name: '逗貓棒', count: 2),
        _Item(id: 'potion01', name: '小型回復藥', count: 6),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: FutureBuilder<_PetDetail>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final d = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 頭圖 + 狀態標籤
              Hero(
                tag: 'pet:${widget.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(widget.imageUrl, height: 240, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  _chip(text: widget.owned ? '已持有' : '未持有',
                        color: widget.owned ? Colors.green : Colors.grey),
                  _chip(text: 'Lv.${d.level}', color: Colors.blue),
                  _chip(text: 'ID ${widget.id}', color: Colors.indigo),
                ],
              ),
              const SizedBox(height: 16),

              // 狀況條（血量、體力、親密度）
              _statusBar(label: '血量', value: d.hp, max: d.hpMax, color: Colors.red),
              const SizedBox(height: 10),
              _statusBar(label: '體力', value: d.energy, max: d.energyMax, color: Colors.orange),
              const SizedBox(height: 10),
              _statusBar(label: '親密度', value: d.intimacy, max: 100, color: Colors.pink),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // 快捷操作
              const Text('快捷操作', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => _useItem(context, 'food01'),
                  icon: const Icon(Icons.restaurant),
                  label: const Text('餵食'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => _play(context),
                  icon: const Icon(Icons.sports_esports),
                  label: const Text('玩耍'),
                )),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _train(context),
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('訓練'),
                )),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _bath(context),
                  icon: const Icon(Icons.shower),
                  label: const Text('洗澡'),
                )),
              ]),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // 常用道具 + 背包入口
              Row(
                children: [
                  const Text('常用道具', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _openInventory(context),
                    icon: const Icon(Icons.backpack),
                    label: const Text('道具背包'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: d.quickItems.map((it) => ActionChip(
                  label: Text('${it.name} ×${it.count}'),
                  avatar: const Icon(Icons.inventory_2, size: 18),
                  onPressed: () => _useItem(context, it.id),
                )).toList(),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // 介紹區
              const Text('介紹', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              const Text('這裡放寵物的詳細描述、來源、稀有度、屬性、技能、取得方式等。'),
            ],
          );
        },
      ),
    );
  }

  // ===== UI helpers & actions =====
  Widget _chip({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.9), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _statusBar({required String label, required int value, required int max, required Color color}) {
    final pct = (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text('$value / $max', style: TextStyle(color: Colors.grey[700])),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct, minHeight: 10, backgroundColor: Colors.black12, color: color),
        ),
      ],
    );
  }

  void _openInventory(BuildContext context) {
    // TODO: 導到你的背包頁路由
    // Navigator.pushNamed(context, '/inventory');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('打開道具背包（示意）')));
  }

  void _useItem(BuildContext context, String itemId) {
    // TODO: 呼叫使用道具 API -> 更新狀態（setState 重取 fetchDetail）
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('使用道具 $itemId（示意）')));
  }

  void _play(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('陪玩增加親密度（示意）')));
  }

  void _train(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('訓練中（示意）')));
  }

  void _bath(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('洗澡中（示意）')));
  }
}
