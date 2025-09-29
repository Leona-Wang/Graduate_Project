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
              const SizedBox(height: 12),

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
              const SizedBox(height: 16),

              _infoRow(
                label: '親密度',
                valueText: d.intimacy.toString(),
                icon: Icons.favorite,
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              ListTile(
                leading: const Icon(Icons.backpack),
                title: const Text('道具背包'),
                subtitle: const Text('前往查看你的道具與提升親密度'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openInventory(context),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // 介紹
              const Text(
                '介紹',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(valueText, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  void _openInventory(BuildContext context) {
    // TODO: 導到你的背包頁路由（由他人實作）
    // Navigator.pushNamed(context, '/inventory');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('將導向：道具背包（示意）')),
    );
  }
}
