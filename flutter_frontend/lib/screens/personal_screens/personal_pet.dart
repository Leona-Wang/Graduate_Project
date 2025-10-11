import 'dart:convert';

import 'package:flutter/material.dart';
import 'personal_pet_detail_page.dart';
import '../../api_client.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home_tab.dart';

import 'package:flutter_frontend/config.dart';

class _Pet {
  final int id;
  final String name;
  final String imageUrl;
  final bool owned;

  _Pet({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.owned,
  });

  factory _Pet.fromJson(Map<String, dynamic> j) => _Pet(
    id: j['id'],
    name: j['name'] ?? '',
    imageUrl: 'assets/pet/${j['id']}.PNG',
    owned: j['hasThisPet'] ?? false,
  );
}

class PersonalPetPage extends StatefulWidget {
  const PersonalPetPage({super.key});

  @override
  State<PersonalPetPage> createState() => _PersonalPetPageState();
}

class _PersonalPetPageState extends State<PersonalPetPage> {
  late Future<List<_Pet>> _future;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _future = _fetchPets();
  }

  void backToHome() => PersonalHomeTab.of(context)?.switchTab(0);

  Future<List<_Pet>> _fetchPets() async {
    setState(() => isLoading = true);

    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final url = ApiPath.getAllPets();
      final uriNum = Uri.parse(url);

      final response = await apiClient.get(uriNum.toString());
      print('fetchNumber response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['pets'] != null) {
          final pets =
              (data['pets'] as List).map((e) => _Pet.fromJson(e)).toList();

          pets.sort((a, b) {
            if (a.owned != b.owned) return a.owned ? -1 : 1;
            return a.name.compareTo(b.name);
          }); //組內排序，已持有在前，按名稱排序

          return pets;
        } else {
          return <_Pet>[];
        }
      } else {
        throw Exception("取得寵物資訊失敗: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("錯誤: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.brown),
            onPressed: backToHome,
            tooltip: '返回主頁',
          ),
        ),
        title: const Text('我的寵物'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final pets = await _fetchPets();
          setState(() {
            _future = Future.value(pets);
          });
        },
        child: FutureBuilder<List<_Pet>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done || isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('載入失敗：${snap.error}'));
            }

            final pets = snap.data ?? [];
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
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => PersonalPetDetailPage(
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pet.owned ? Colors.amber : Colors.grey.shade300,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
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
                      ColorFiltered(
                        colorFilter:
                            pet.owned
                                ? const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.multiply,
                                )
                                : const ColorFilter.matrix(<double>[
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ]),
                        child: Opacity(
                          opacity: pet.owned ? 1 : 0.45,
                          child: Image.asset(pet.imageUrl, fit: BoxFit.cover),
                        ),
                      ),
                      /*
                      if (pet.owned)
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '已持有',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),*/
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
        ),
      ),
    );
  }
}
