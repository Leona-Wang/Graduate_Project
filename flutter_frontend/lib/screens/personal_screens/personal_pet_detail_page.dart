import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_frontend/base_config.dart';
import '../../api_client.dart';
import 'package:flutter_frontend/config.dart';

class PersonalPetDetailPage extends StatefulWidget {
  const PersonalPetDetailPage({
    super.key,
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.owned,
  });

  final int id;
  final String name;
  final String imageUrl;
  final bool owned;

  @override
  State<PersonalPetDetailPage> createState() => _PersonalPetDetailPageState();
}

class _PetDetail {
  final String name;
  final String description;
  final int point;

  _PetDetail({
    required this.name,
    required this.description,
    required this.point,
  });

  factory _PetDetail.fromJson(Map<String, dynamic> json) {
    return _PetDetail(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      point: json['point'] ?? 0,
    );
  }
}

class _PersonalPetDetailPageState extends State<PersonalPetDetailPage> {
  late Future<_PetDetail> _future;
  final GlobalKey<_PetProgressBarState> petProgressBarKey =
      GlobalKey<_PetProgressBarState>();

  bool isLoading = false;

  int currentPoint = 0;

  @override
  void initState() {
    super.initState();
    _future = fetchDetail(widget.id).then((detail) {
      currentPoint = detail.point; // 初始就存好 currentPoint
      return detail;
    });
  }

  //獲取寵物詳情
  Future<_PetDetail> fetchDetail(int id) async {
    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final url = ApiPath.petDetail(id);
      final response = await apiClient.get(url);
      print('fetchDetail response status: ${response.statusCode}');
      print('fetchDetail response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          currentPoint = data['point'];
          return _PetDetail.fromJson(data);
        } else {
          throw Exception("取得寵物詳情失敗：success=false");
        }
      } else {
        throw Exception("取得寵物詳情失敗：${response.statusCode}");
      }
    } catch (e) {
      throw Exception("錯誤: $e");
    }
  }

  //獲取道具清單
  Future<List<Map<String, dynamic>>> _fetchInventory() async {
    setState(() => isLoading = true);

    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final url = ApiPath.getPowerupList;
      final uriItem = Uri.parse(url);

      final response = await apiClient.get(uriItem.toString());
      print('fetchInventory response status: ${response.statusCode}');
      print('fetchInventory response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['itemList'] != null) {
          // 確保 itemList 是 List
          final List<dynamic> items = data['itemList'];
          return items.map((e) {
            final rawUrl = e['imageUrl'] as String?;
            final fullUrl =
                (rawUrl != null && !rawUrl.startsWith('http'))
                    ? '${BaseConfig.baseUrl}$rawUrl'
                    : rawUrl ?? '';

            return {
              "name": e['name'],
              "quantity": e['quantity'],
              "imageUrl": fullUrl,
            };
          }).toList();
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      print("fetchInventory error: $e");
      return [];
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  //增加好感度
  Future<Map<String, dynamic>> increasePetIntimacy({
    required String itemName,
    required String petName,
    required int quantity,
  }) async {
    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final url = ApiPath.deductPowerup;
      final favUri = Uri.parse(url);

      final body = {
        "powerupName": itemName,
        "petName": petName,
        'quantity': quantity,
      };

      final response = await apiClient.post(favUri.toString(), body);

      print('increasePetIntimacy response: ${response.statusCode}');
      print('increasePetIntimacy body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception("增加親密度失敗: ${response.statusCode}");
      }
    } catch (e) {
      print("increasePetIntimacy error: $e");
      throw Exception("錯誤: $e");
    }
  }

  void _useItemOnPet(String itemName, String petName, int quantity) async {
    try {
      final result = await increasePetIntimacy(
        itemName: itemName,
        petName: petName,
        quantity: quantity,
      );
      if (result['success'] == true) {
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text("成功"),
              content: const Text("親密度提升成功！"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text("確定"),
                ),
              ],
            );
          },
        );

        final updatedDetail = await fetchDetail(widget.id);
        print('updatedDetail.point: ${updatedDetail.point}');

        if (!mounted) return;
        setState(() {
          // 用新的 Future 包裝結果，觸發 FutureBuilder rebuild
          _future = Future.value(updatedDetail);
          currentPoint = updatedDetail.point;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'] ?? "增加親密度失敗")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("發生錯誤: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: FutureBuilder<_PetDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("錯誤: ${snap.error}"));
          }
          if (!snap.hasData) {
            return const Center(child: Text("無法取得寵物詳情"));
          }

          final d = snap.data!;
          final isMaxIntimacy = d.point >= 100;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 頭圖
              Hero(
                tag: 'pet:${widget.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    widget.imageUrl,
                    height: 450,
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
                    color: widget.owned ? Colors.amber : Colors.grey,
                  ),
                  _chip(text: 'ID ${widget.id}', color: Colors.brown),
                ],
              ),
              const SizedBox(height: 20),

              initmacyBar(),
              const SizedBox(height: 28),

              if (widget.owned && !isMaxIntimacy)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _openInventory(),
                    icon: const Icon(Icons.favorite),
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
                )
              else if (widget.owned && isMaxIntimacy)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      "親密度已達最大值",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      "尚未擁有此寵物，無法提升親密度",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
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
              const SizedBox(height: 4),
              Text(d.description),
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

  //親密度顯示
  Widget initmacyBar() {
    final progress = (currentPoint / 100).clamp(0.0, 1.0);
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: PetProgressBar(progress: progress),
      ),
    );
  }

  //打開道具清單
  void _openInventory() async {
    if (currentPoint >= 100) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('親密度已達最大值')));
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
      useRootNavigator: true,
    );
    try {
      final items = await _fetchInventory();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (items.isEmpty) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder:
              (BuildContext dialogContext) => AlertDialog(
                title: const Text("提醒"),
                content: const Text("糧倉空啦!快去為你的寵物獲得道具吧!"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text("確定"),
                  ),
                ],
              ),
        );
        return;
      }

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
              final hasSelectableItem = counts.any((c) => c > 0);

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
                      child:
                          items.isEmpty
                              ? const Center(
                                child: Text(
                                  "糧倉空啦!快去為你的寵物獲得道具吧!",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                              : GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                itemCount: items.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisExtent: 260,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  final owned = item['quantity'] as int;
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          height: 100,
                                          padding: const EdgeInsets.all(8),
                                          child: Image.network(
                                            item['imageUrl'] as String,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (_, __, ___) => const Icon(
                                                  Icons.error,
                                                  size: 48,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item["name"] as String,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "持有 $owned",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                              onPressed:
                                                  counts[index] > 0
                                                      ? () => setState(
                                                        () => counts[index]--,
                                                      )
                                                      : null,
                                            ),
                                            Text(
                                              "${counts[index]}",
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                              ),
                                              onPressed:
                                                  counts[index] < owned
                                                      ? () => setState(
                                                        () => counts[index]++,
                                                      )
                                                      : null,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                    ),
                    if (hasSelectableItem)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            for (int i = 0; i < items.length; i++) {
                              if (counts[i] > 0) {
                                _useItemOnPet(
                                  items[i]['name'],
                                  widget.name,
                                  counts[i],
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("確認"),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("載入道具失敗: $e")));
    }
  }
}

//進度條動畫
class PetProgressBar extends StatefulWidget {
  final double progress; // 從外部傳入進度

  const PetProgressBar({super.key, required this.progress});

  @override
  State<PetProgressBar> createState() => _PetProgressBarState();
}

class _PetProgressBarState extends State<PetProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _oldProgress = widget.progress;
    _animateProgress(0.0, widget.progress);
  }

  @override
  void didUpdateWidget(covariant PetProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _animateProgress(_oldProgress, widget.progress);
  }

  void _animateProgress(double from, double to) {
    _controller.reset();
    _animation = Tween<double>(begin: from, end: to.clamp(0.0, 1.0)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    )..addListener(() {
      setState(() {});
    });
    _controller.forward();
    _oldProgress = to.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayText =
        (_animation.value >= 1.0)
            ? "已達最大親密度"
            : "${(_animation.value * 100).toInt()}%";
    return Stack(
      alignment: Alignment.center,
      children: [
        LinearProgressIndicator(
          value: _animation.value,
          minHeight: 16,
          backgroundColor: Colors.grey[300],
          color: Colors.amber,
          borderRadius: BorderRadius.circular(8),
        ),
        Text(
          displayText,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
