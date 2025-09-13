import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home_tab.dart';

class PersonalShopPage extends StatefulWidget {
  const PersonalShopPage({super.key});

  @override
  State<PersonalShopPage> createState() => PersonalShopPageState();
}

class PersonalShopPageState extends State<PersonalShopPage> {
  final random = Random();

  int coinBalance = 120; // 初始持有金幣（可改）
  int gachaCost = 50;

  // 示範商品資料
  final List<ShopItem> items = [
    ShopItem(id: 1, name: 'A商品', price: 80, icon: Icons.backpack),
    ShopItem(id: 2, name: 'B商品', price: 120, icon: Icons.crop_square),
    ShopItem(id: 3, name: 'C商品', price: 60, icon: Icons.badge),
    ShopItem(id: 4, name: 'D商品', price: 100, icon: Icons.expand),
  ];

  // 扭蛋獎池（可自行調整機率：用 weight 權重）
  final List<GachaPrize> prizes = [
    GachaPrize(name: '安慰獎勵', type: PrizeType.coin, value: 10, weight: 45),
    GachaPrize(name: '普通獎勵', type: PrizeType.item, value: 1, weight: 30),
    GachaPrize(name: '稀有獎勵', type: PrizeType.coin, value: 80, weight: 15),
    GachaPrize(name: '超稀有獎勵', type: PrizeType.item, value: 1, weight: 7),
    GachaPrize(name: '傳說獎勵', type: PrizeType.coin, value: 300, weight: 3),
  ];

  void backToHome() {
    PersonalHomeTab.of(context)?.switchTab(0);
  }

  void topUp(int amount) {
    setState(() {
      coinBalance += amount;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已儲值 $amount 金幣')),
    );
  }

  void purchaseItem(ShopItem item) {
    if (coinBalance < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('金幣不足')),
      );
      return;
    }
    setState(() {
      coinBalance -= item.price;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已購買：${item.name}')),
    );
  }

  void spinGacha() {
    if (coinBalance < gachaCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('金幣不足，無法抽取')),
      );
      return;
    }

    setState(() {
      coinBalance -= gachaCost;
    });

    final prize = pickPrizeByWeight(prizes, random);

    // 結算獎勵
    if (prize.type == PrizeType.coin) {
      setState(() {
        coinBalance += prize.value;
      });
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('扭蛋結果'),
        content: Text(prize.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  // 權重隨機
  GachaPrize pickPrizeByWeight(List<GachaPrize> pool, Random rng) {
    final total = pool.fold<int>(0, (sum, p) => sum + p.weight);
    int roll = rng.nextInt(total) + 1;
    for (final p in pool) {
      roll -= p.weight;
      if (roll <= 0) return p;
    }
    return pool.last;
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
            // 金幣資訊
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, size: 32, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '持有金幣：$coinBalance',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _showTopUpSheet(),
                      icon: const Icon(Icons.add),
                      label: const Text('儲值'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 克金（儲值）區域（快捷按鈕）
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

            // 商城商品
            Text('商品清單', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 每列兩個
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
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text('價格：${item.price}'),
                        FilledButton(
                          onPressed: () => purchaseItem(item),
                          child: const Text('購買'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // 扭蛋機
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
                        const Icon(Icons.toys, size: 32, color: Colors.pinkAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('每抽 $gachaCost 金幣', style: theme.textTheme.bodyLarge),
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
                            onPressed: spinGacha,
                            child: const Text('單抽'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              // 十連：先檢查是否足夠
                              final totalCost = gachaCost * 10;
                              if (coinBalance < totalCost) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('金幣不足（需要 $totalCost）')),
                                );
                                return;
                              }
                              // 扣款並連抽
                              setState(() {
                                coinBalance -= totalCost;
                              });
                              final results = <GachaPrize>[];
                              for (int i = 0; i < 10; i++) {
                                final p = pickPrizeByWeight(prizes, random);
                                results.add(p);
                                if (p.type == PrizeType.coin) {
                                  setState(() {
                                    coinBalance += p.value;
                                  });
                                }
                              }
                              _showTenPullResults(results);
                            },
                            child: const Text('十連'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ======== UI Helpers ========

  Widget _topUpButton(int amount, String label) {
    return OutlinedButton(
      onPressed: () => topUp(amount),
      child: Text('$label'),
    );
  }

  void _showTopUpSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('選擇儲值方案', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.flash_on),
              title: const Text('小額 +100'),
              trailing: FilledButton(onPressed: () => _closeThenTopUp(100), child: const Text('購買')),
            ),
            ListTile(
              leading: const Icon(Icons.bolt),
              title: const Text('中額 +300'),
              trailing: FilledButton(onPressed: () => _closeThenTopUp(300), child: const Text('購買')),
            ),
            ListTile(
              leading: const Icon(Icons.local_fire_department),
              title: const Text('大額 +1000'),
              trailing: FilledButton(onPressed: () => _closeThenTopUp(1000), child: const Text('購買')),
            ),
          ],
        ),
      ),
    );
  }

  void _closeThenTopUp(int amount) {
    Navigator.pop(context);
    topUp(amount);
  }

  void _showGachaInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('扭蛋機說明'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('每抽 $gachaCost 金幣。'),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('獎池示意：'),
            ),
            const SizedBox(height: 6),
            ...prizes.map((p) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text('• ${p.name}（權重：${p.weight}）'),
                )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('了解')),
        ],
      ),
    );
  }

  void _showTenPullResults(List<GachaPrize> results) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('十連結果'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 12),
            itemBuilder: (_, i) {
              final p = results[i];
              return Row(
                children: [
                  Icon(
                    p.type == PrizeType.coin ? Icons.monetization_on : Icons.card_giftcard,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p.name)),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('收下')),
        ],
      ),
    );
  }
}

// ======== Models ========

class ShopItem {
  final int id;
  final String name;
  final int price;
  final IconData icon;

  ShopItem({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
  });
}

enum PrizeType { coin, item }

class GachaPrize {
  final String name;
  final PrizeType type;
  final int value; // coin：加幣數；item：可先用 1 代表獲得一次
  final int weight; // 權重（機率比）

  GachaPrize({
    required this.name,
    required this.type,
    required this.value,
    required this.weight,
  });
}
