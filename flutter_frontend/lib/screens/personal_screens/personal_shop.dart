import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home_tab.dart';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/api_client.dart';
import 'package:flutter_frontend/base_config.dart';

class PersonalShopPage extends StatefulWidget {
  const PersonalShopPage({super.key});

  @override
  State<PersonalShopPage> createState() => PersonalShopPageState();
}

class PersonalShopPageState extends State<PersonalShopPage> {
  // 之後餘額可改為向後端查詢；目前僅 UI 顯示，不參與扣款（由後端主導）
  int coinBalance = 10000;

  // 後端規格：每抽 5 金幣（僅顯示用）
  static const int gachaCost = 5;

  bool isSpinning = false;

  // 假資料（購買/儲值都先「敬請期待」）
  final List<ShopItem> items = const [
    ShopItem(id: 1, name: 'A商品', price: 80, icon: Icons.backpack),
    ShopItem(id: 2, name: 'B商品', price: 120, icon: Icons.crop_square),
    ShopItem(id: 3, name: 'C商品', price: 60, icon: Icons.badge),
    ShopItem(id: 4, name: 'D商品', price: 100, icon: Icons.expand),
  ];

  void backToHome() {
    PersonalHomeTab.of(context)?.switchTab(0);
  }

  // ===== 公用：敬請期待 =====
  void _comingSoon([String? feature]) {
    showDialog(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('敬請期待'),
            content: Text(feature ?? '功能即將開放，請稍候～'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('了解'),
              ),
            ],
          ),
    );
  }

  // ===== API：寵物扭蛋（依你提供的介面）=====
  // POST ${BaseConfig.baseUrl}/pets/gacha/
  Future<PetGachaResult> _gachaOnce() async {
    final apiClient = ApiClient();
    await apiClient.init();

    final url = ApiPath.gachaPet; // e.g. ${BaseConfig.baseUrl}/pets/gacha/
    final resp = await apiClient.post(ApiPath.gachaPet, {});

    // 把錯誤內容 decode 出來，方便debug
    Map<String, dynamic>? errJson;
    try {
      errJson = jsonDecode(resp.body);
    } catch (_) {}

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(resp.body);
      if (data['success'] == true && data['pet'] != null) {
        final pet = data['pet'] as Map<String, dynamic>;
        return PetGachaResult(
          success: true,
          pet: PetModel(
            id: pet['id'] ?? 0,
            name: (pet['name'] ?? '').toString(),
            description: (pet['description'] ?? '').toString(),
            imageUrl: (pet['imageUrl'] ?? '').toString(),
            newPet: pet['newPet'] == true,
          ),
        );
      }
      throw Exception('回傳格式不正確：${resp.body}');
    } else if (resp.statusCode == 401) {
      // 常見：未帶登入
      throw Exception(
        '未授權（401）。請確認已登入並帶到 Authorization header。伺服器回應：${resp.body}',
      );
    } else if (resp.statusCode == 400) {
      // 常見：Content-Type 錯、或缺欄位、或餘額不足等業務錯
      final msg =
          (errJson?['detail'] ?? errJson?['message'] ?? resp.body).toString();
      throw Exception('扭蛋失敗（400）：$msg');
    } else {
      throw Exception('扭蛋失敗（${resp.statusCode}）：${resp.body}');
    }
  }

  // ===== 抽卡流程（前端）=====
  Future<void> spinGacha() async {
    if (isSpinning) return;
    setState(() => isSpinning = true);

    try {
      final result = await _gachaOnce();
      if (!mounted) return;
      await _showSingleResult(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())), // 直接顯示 Exception 內容
      );
    }
  }

  Future<void> spinGachaTen() async {
    if (isSpinning) return;
    setState(() => isSpinning = true);

    final results = <PetGachaResult>[];
    try {
      for (int i = 0; i < 10; i++) {
        try {
          final r = await _gachaOnce();
          results.add(r);
        } catch (e) {
          // 單抽錯誤就略過，但在彙總結果時可顯示「失敗」項（這裡簡化為不顯示）
          debugPrint('十連第 ${i + 1} 抽失敗：$e');
        }
      }
      if (!mounted) return;
      await _showTenResults(results);
    } finally {
      if (mounted) setState(() => isSpinning = false);
    }
  }

  // ===== 對話框（使用內層 context）=====
  Future<void> _showSingleResult(PetGachaResult r) {
    final img = _fullMediaUrl(r.pet.imageUrl);
    return showDialog(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('扭蛋結果'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (img != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      img,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  r.pet.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(r.pet.description.isEmpty ? '—' : r.pet.description),
                const SizedBox(height: 8),
                if (r.pet.newPet)
                  const Chip(label: Text('新獲得！'))
                else
                  const Chip(label: Text('已有寵物（親密度 +10，若已滿不再增加）')),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('確定'),
              ),
            ],
          ),
    );
  }

  Future<void> _showTenResults(List<PetGachaResult> results) {
    return showDialog(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('十連結果'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (_, i) {
                  final r = results[i];
                  final img = _fullMediaUrl(r.pet.imageUrl);
                  return Row(
                    children: [
                      if (img != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            img,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        const Icon(Icons.pets),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.pet.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!r.pet.newPet)
                              const Text(
                                '已有寵物（親密度 +10）',
                                style: TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      if (r.pet.newPet) const Chip(label: Text('新')),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('收下'),
              ),
            ],
          ),
    );
  }

  // 後端若回 /media/...，這裡補完整網址
  String? _fullMediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${BaseConfig.baseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 6.0, bottom: 6.0),
          child: CircleAvatar(
            backgroundColor: Colors.amberAccent,
            child: IconButton(
              onPressed: backToHome,
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.brown),
              tooltip: '返回主頁',
            ),
          ),
        ),
        title: const Text('商城'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 金幣資訊（暫時顯示本地數字，後端接好再同步）
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      size: 32,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '持有金幣：$coinBalance',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _comingSoon('儲值功能將於正式版開放'),
                      icon: const Icon(Icons.add),
                      label: const Text('儲值'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 扭蛋機（往上放）
            Text('扭蛋機', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.toys,
                          size: 32,
                          color: Colors.pinkAccent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '每抽 $gachaCost 金幣',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: '說明',
                          onPressed: _showGachaInfo,
                          icon: const Icon(Icons.info_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSpinning ? null : spinGacha,
                            child:
                                isSpinning
                                    ? const Text('抽卡中…')
                                    : const Text('單抽'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: isSpinning ? null : spinGachaTen,
                            child:
                                isSpinning
                                    ? const Text('抽卡中…')
                                    : const Text('十連'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 克金（儲值）快捷區 → 敬請期待
            Text('克金區域', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _topUpButton(100, '小額 +100')),
                const SizedBox(width: 8),
                Expanded(child: _topUpButton(300, '中額 +300')),
                const SizedBox(width: 8),
                Expanded(child: _topUpButton(1000, '大額 +1000')),
              ],
            ),

            const SizedBox(height: 24),

            // 商品清單 → 敬請期待
            Text('商品清單', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (_, i) {
                final item = items[i];
                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(item.icon, size: 48),
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text('價格：${item.price}'),
                        FilledButton(
                          onPressed: () => _comingSoon('購買功能將於正式版開放'),
                          child: const Text('購買'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ===== UI Helpers =====
  Widget _topUpButton(int amount, String label) {
    return OutlinedButton(
      onPressed: () => _comingSoon('儲值功能將於正式版開放'),
      child: Text(label),
    );
  }

  void _showGachaInfo() {
    showDialog(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('扭蛋機說明'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('本轉蛋包含六種寵物。'),
                SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('• 單抽花費五金幣、十抽花費五十金幣。'),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('• 抽到重複的寵物會增加親密值。'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('了解'),
              ),
            ],
          ),
    );
  }
}

// ===== Models =====

class ShopItem {
  final int id;
  final String name;
  final int price;
  final IconData icon;
  const ShopItem({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
  });
}

class PetGachaResult {
  final bool success;
  final PetModel pet;
  PetGachaResult({required this.success, required this.pet});
}

class PetModel {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final bool newPet;
  PetModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.newPet,
  });
}
