import 'package:flutter/material.dart';
import 'personal_pet_detail_page.dart';

class _Pet {
  final String id;
  final String name;
  final String imageUrl;
  final bool owned;

  _Pet({required this.id, required this.name, required this.imageUrl, required this.owned});

  factory _Pet.fromJson(Map<String, dynamic> j) => _Pet(
        id: j['id'].toString(),
        name: j['name'] ?? '',
        imageUrl: j['image'] ?? '',
        owned: j['owned'] ?? false,
      );
}

class PersonalPetPage extends StatefulWidget {
  const PersonalPetPage({super.key});

  @override
  State<PersonalPetPage> createState() => _PersonalPetPageState();
}

class _PersonalPetPageState extends State<PersonalPetPage> {
  late Future<List<_Pet>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchPets();
  }

  Future<List<_Pet>> _fetchPets() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      _Pet(id: '1', name: '洋蔥', imageUrl: 'https://cataas.com/cat?1', owned: true),
      _Pet(id: '2', name: '胡蘿蔔', imageUrl: 'https://cataas.com/cat?2', owned: false),
      _Pet(id: '3', name: '茄子', imageUrl: 'https://cataas.com/cat?3', owned: true),
      _Pet(id: '4', name: '西瓜', imageUrl: 'https://cataas.com/cat?4', owned: false),
      _Pet(id: '5', name: '蘋果', imageUrl: 'https://cataas.com/cat?5', owned: false),
      _Pet(id: '6', name: '水梨', imageUrl: 'https://cataas.com/cat?6', owned: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的寵物')),
      body: FutureBuilder<List<_Pet>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('載入失敗：${snap.error}'));
          }
          final pets = [...(snap.data ?? <_Pet>[])];

          // ✅ 排序：已持有在前、未持有在後；同組內再依名稱排序
          pets.sort((a, b) {
            if (a.owned != b.owned) return a.owned ? -1 : 1;
            return a.name.compareTo(b.name);
          });

          if (pets.isEmpty) {
            return const Center(child: Text('目前沒有寵物資料'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3 / 4,
            ),
            itemCount: pets.length,
            itemBuilder: (_, i) {
              final p = pets[i];
              return _PetCard(
                pet: p,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PersonalPetDetailPage(
                      id: p.id,
                      name: p.name,
                      imageUrl: p.imageUrl,
                      owned: p.owned,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet, required this.onTap});
  final _Pet pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Hero(
            tag: 'pet:${pet.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 未持有：灰階 + 降透明；已持有：正常
                  ColorFiltered(
                    colorFilter: pet.owned
                        ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                        : const ColorFilter.matrix(<double>[
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0, 0, 0, 1, 0,
                          ]),
                    child: Opacity(
                      opacity: pet.owned ? 1 : 0.45,
                      child: Image.network(pet.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                  if (pet.owned)
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text('已持有', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          pet.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: pet.owned ? null : Colors.grey[600],
          ),
        ),
      ],
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: pet.owned ? Colors.green : Colors.grey.shade300),
        ),
        child: Padding(padding: const EdgeInsets.all(8), child: content),
      ),
    );
  }
}
