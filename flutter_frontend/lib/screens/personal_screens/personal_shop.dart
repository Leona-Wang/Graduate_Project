import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home_tab.dart';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/api_client.dart';
import 'package:flutter_frontend/base_config.dart';

//import 'dart:math';
import 'package:animate_do/animate_do.dart';

class PersonalShopPage extends StatefulWidget {
  const PersonalShopPage({super.key});

  @override
  State<PersonalShopPage> createState() => _PersonalShopPageState();
}

class _PersonalShopPageState extends State<PersonalShopPage> {
  int coinBalance = 10000;
  static const int gachaCost = 5;
  bool isSpinning = false;

  final List<ShopItem> items = const [
    ShopItem(id: 1, name: 'A商品', price: 80, icon: Icons.backpack),
    ShopItem(id: 2, name: 'B商品', price: 120, icon: Icons.crop_square),
    ShopItem(id: 3, name: 'C商品', price: 60, icon: Icons.badge),
    ShopItem(id: 4, name: 'D商品', price: 100, icon: Icons.expand),
  ];

  void backToHome() => PersonalHomeTab.of(context)?.switchTab(0);

  // ===== 通用對話框 =====
  Future<void> _showDialog(String title, Widget content) {
    return showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: content,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('了解'),
              ),
            ],
          ),
    );
  }

  void _comingSoon([String? feature]) {
    _showDialog('敬請期待', Text(feature ?? '功能即將開放，請稍候～'));
  }

  void _showGachaInfo() {
    _showDialog(
      '扭蛋機說明',
      const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('本轉蛋包含六種寵物。'),
          SizedBox(height: 6),
          Text('• 單抽花費五金幣、十抽花費五十金幣。'),
          Text('• 抽到重複的寵物會增加親密值。'),
        ],
      ),
    );
  }

  // ===== API：寵物扭蛋 =====
  Future<PetGachaResult> _gachaOnce() async {
    try {
      final apiClient = ApiClient();
      await apiClient.init();
      final resp = await apiClient.post(ApiPath.gachaPet, {});

      Map<String, dynamic> json = {};
      try {
        json = jsonDecode(resp.body);
      } catch (e) {
        debugPrint("JSON 解析錯誤: $e");
      }

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        if (json['success'] == true && json['pet'] != null) {
          final pet = json['pet'] as Map<String, dynamic>;
          return PetGachaResult(success: true, pet: PetModel.fromJson(pet));
        }
      } else if (resp.statusCode == 400) {
        // 金幣不足時
        coinException();
        // 確保回傳失敗結果，而不是 null
        return PetGachaResult(
          success: false,
          pet: PetModel(
            id: 0,
            name: '',
            description: '金幣不足',
            imageUrl: '',
            newPet: false,
          ),
        );
      }
    } catch (e, stack) {
      debugPrint("發生例外: $e\n$stack");
    }

    // 預設失敗結果（避免回傳 null）
    return PetGachaResult(
      success: false,
      pet: PetModel(
        id: 0,
        name: '',
        description: '抽卡失敗',
        imageUrl: '',
        newPet: false,
      ),
    );
  }

  void coinException() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("金幣數量不足 QQ"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("確認"),
            ),
          ],
        );
      },
    );
  }

  // ===== 抽卡流程 =====
  Future<void> spinGacha() async {
    if (isSpinning) return;
    setState(() => isSpinning = true);

    try {
      final result = await _gachaOnce();

      // 若抽卡失敗或金幣不足，立即停止，顯示提示
      if (!result.success) {
        if (mounted) {
          debugPrint('金幣不足或抽卡失敗，已停止抽卡');
          //coinException(); //直接跳出彈窗
        }
        return; // 不再繼續顯示抽卡結果
      }

      // 抽卡成功才顯示結果
      await _showSingleResult(result);
    } catch (e) {
      _showSnack('發生錯誤：$e');
    } finally {
      if (mounted) setState(() => isSpinning = false);
    }
  }

  Future<void> spinGachaTen() async {
    if (isSpinning) return;
    setState(() => isSpinning = true);

    final results = <PetGachaResult>[];

    try {
      for (int i = 0; i < 10; i++) {
        final add = await _gachaOnce();
        // 若金幣不足或失敗 → 直接停止十連抽
        if (!add.success) {
          if (mounted) {
            debugPrint('金幣不足或抽卡失敗，已停止十連抽');
          }
          break;
        }
        results.add(add);
      }

      if (mounted && results.isNotEmpty) {
        await _showTenResults(results);
      }
    } catch (e) {
      debugPrint("十連抽錯誤: $e");
    } finally {
      if (mounted) setState(() => isSpinning = false);
    }
  }

  // ===== 結果顯示 =====
  Future<void> _showSingleResult(PetGachaResult r) async {
    final img = _fullMediaUrl(r.pet.imageUrl);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ZoomIn(
            duration: const Duration(milliseconds: 500),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '🎉 新夥伴！',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (img != null)
                    BounceInDown(
                      duration: const Duration(milliseconds: 800),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          img,
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    r.pet.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.pet.description.isEmpty ? '—' : r.pet.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Chip(
                    label: Text(r.pet.newPet ? '新獲得！' : '已有寵物（親密度 +10）'),
                    backgroundColor:
                        r.pet.newPet ? Colors.green[100] : Colors.grey[200],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('確認'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _showTenResults(List<PetGachaResult> results) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => FadeIn(
            duration: const Duration(milliseconds: 400),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '🌟 十連結果',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (_, i) {
                    final r = results[i];
                    final img = _fullMediaUrl(r.pet.imageUrl);
                    return ZoomIn(
                      duration: Duration(milliseconds: 100 * i + 200),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.amber[50],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(2, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (img != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  img,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              r.pet.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (r.pet.newPet)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Chip(
                                  label: Text('新'),
                                  backgroundColor: Colors.greenAccent,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('確認'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String? _fullMediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${BaseConfig.baseUrl}$path';
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        title: const Text('商城'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCardSection(
              icon: Icons.monetization_on,
              iconColor: Colors.amber,
              title: '持有金幣：$coinBalance',
              trailing: FilledButton.icon(
                onPressed: () => _comingSoon('儲值功能將於正式版開放'),
                icon: const Icon(Icons.add),
                label: const Text('儲值'),
              ),
            ),
            const SizedBox(height: 16),

            _buildGachaSection(theme),
            const SizedBox(height: 24),

            _buildTopUpSection(),
            const SizedBox(height: 24),

            _buildShopSection(theme),
          ],
        ),
      ),
    );
  }

  // ===== 各區塊 =====
  Widget _buildCardSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildGachaSection(ThemeData theme) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.toys, size: 32, color: Colors.pinkAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '每抽 $gachaCost 金幣',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                IconButton(
                  onPressed: _showGachaInfo,
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 扭蛋球動畫顯示區
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child:
                  isSpinning
                      ? RotationTransition(
                        turns: const AlwaysStoppedAnimation(1),
                        child: Image.asset(
                          'assets/pet/Gotcha.png',
                          key: const ValueKey('spinning'),
                          width: 100,
                          height: 100,
                        ),
                      )
                      : Image.asset(
                        'assets/pet/Gotcha.png',
                        key: const ValueKey('idle'),
                        width: 100,
                        height: 100,
                      ),
            ),
            const SizedBox(height: 20),

            // 抽卡按鈕區
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSpinning ? null : spinGacha,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.amber),
                    ),
                    child: Text(isSpinning ? '抽卡中…' : '單抽'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isSpinning ? null : spinGachaTen,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber[400],
                    ),
                    child: Text(isSpinning ? '抽卡中…' : '十連'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopUpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '克金區域',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final amount in [100, 300, 1000])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    onPressed: () => _comingSoon('儲值功能將於正式版開放'),
                    child: Text('儲值 +$amount'),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildShopSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '商品清單',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
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
      ],
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

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      newPet: json['newPet'] == true,
    );
  }
}

class PetGachaResult {
  final bool success;
  final PetModel pet;
  PetGachaResult({required this.success, required this.pet});
}
