import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../config.dart';

class PersonalSignupPage extends StatefulWidget {
  final String personalEmail;
  const PersonalSignupPage({super.key, required this.personalEmail});

  @override
  State<PersonalSignupPage> createState() => PersonalSignupState();
}

class PersonalSignupState extends State<PersonalSignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  String? _selectLocation;
  Set<String> _selectPrefer = Set.from([]);
  late String personalEmail;

  bool _isPasswordState = false;
  bool _isLoading = false;

  String _errorMessage = '';

  // 大頭照檔案
  File? _avatarFile;
  final picker = ImagePicker();

  // 選取圖片
  Future<void> _pickAvatar() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarFile = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.personalEmail;
  }

  void _nextStep() {
    final email = _emailController.text.trim();
    final name = _nicknameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = '請輸入正確的email');
      return;
    }
    if (name.isEmpty) {
      setState(() => _errorMessage = '請輸入暱稱');
      return;
    }
    if (_selectLocation == null) {
      setState(() => _errorMessage = '請選擇地區');
      return;
    }
    if (_selectPrefer.isEmpty) {
      setState(() => _errorMessage = '請選擇偏好活動');
      return;
    }
    setState(() {
      _isPasswordState = true;
      _errorMessage = "";
    });
  }

  Future<void> _submitRegister() async {
    final personalPassword = _passwordController.text.trim();
    final confirmPassword = _confirmController.text.trim();

    if (personalPassword.isEmpty) {
      setState(() => _errorMessage = '請設定密碼');
      return;
    }
    if (personalPassword.length < 8) {
      setState(() => _errorMessage = '密碼須至少8個字元');
      return;
    }
    if (personalPassword != confirmPassword) {
      setState(() => _errorMessage = '密碼輸入不一致');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. 先建立帳號（密碼 API）
      final uriPassword = Uri.parse(ApiPath.createPersonalUser);
      final accountCreate = await http.post(
        uriPassword,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'personalEmail': _emailController.text.trim(),
          'personalPassword': personalPassword,
          'personalPasswordConfirm': confirmPassword,
        }),
      );

      // 2. 再建立個人資料（用 Multipart 上傳圖片）
      final uriData = Uri.parse(ApiPath.createPersonalInfo);
      var request = http.MultipartRequest('POST', uriData);
      request.fields['email'] = _emailController.text.trim();
      request.fields['nickname'] = _nicknameController.text.trim();
      request.fields['location'] = _selectLocation ?? '';
      request.fields['eventType'] = jsonEncode(_selectPrefer.toList());

      if (_avatarFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('avatar', _avatarFile!.path),
        );
      }

      var infoResponse = await request.send();

      if (accountCreate.statusCode == 200 && infoResponse.statusCode == 200) {
        _showMessage('註冊成功!');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/personal_signin',
          ModalRoute.withName('/'),
        );
      } else if (accountCreate.statusCode != 200) {
        setState(() => _errorMessage = '密碼設定失敗:${accountCreate.body}');
      } else {
        setState(() => _errorMessage = '個人資料建立失敗:${infoResponse.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = '錯誤:$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  //地區單選清單
  Widget buildLocationField() {
    final options = [
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
    ];

    return InkWell(
      onTap: () {
        String? tempSelected = _selectLocation;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '請選擇經常活動的地區',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children:
                              options.map((e) {
                                return RadioListTile<String>(
                                  value: e,
                                  groupValue: tempSelected,
                                  title: Text(e),
                                  onChanged: (val) {
                                    setSheetState(() {
                                      tempSelected = val;
                                    });
                                    setState(() {
                                      _selectLocation = val;
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: '經常活動的地區',
        ),
        child: Text(
          _selectLocation ?? '請選擇您經常活動的地區',
          style: TextStyle(
            color: _selectLocation == null ? Colors.grey : Colors.black,
          ),
        ),
      ),
    );
  }

  //偏好活動複選清單
  Widget buildPreferType() {
    final options = [
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
    ];

    return InkWell(
      onTap: () {
        final tempSelected = Set<String>.from(_selectPrefer);

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                List<String> sortedOptions = [
                  ...options.where((e) => tempSelected.contains(e)),
                  ...options.where((e) => !tempSelected.contains(e)),
                ];

                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '選擇偏好活動類型',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children:
                              sortedOptions.map((e) {
                                return CheckboxListTile(
                                  value: tempSelected.contains(e),
                                  title: Text(e),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  onChanged: (_) {
                                    setSheetState(() {
                                      if (tempSelected.contains(e)) {
                                        tempSelected.remove(e);
                                      } else {
                                        tempSelected.add(e);
                                      }
                                      sortedOptions = [
                                        ...options.where(
                                          (x) => tempSelected.contains(x),
                                        ),
                                        ...options.where(
                                          (x) => !tempSelected.contains(x),
                                        ),
                                      ];
                                    });
                                    setState(() {
                                      _selectPrefer = tempSelected;
                                    }); //及時寫回外層
                                  },
                                );
                              }).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('關閉'),
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
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: '偏好活動類型',
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children:
              _selectPrefer.isEmpty
                  ? [const Text('請選擇您偏好的活動類型')]
                  : _selectPrefer.map((e) {
                    return Chip(
                      label: Text(e),
                      onDeleted: () {
                        setState(() {
                          _selectPrefer.remove(e);
                        });
                      },
                    );
                  }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('註冊個人帳號')),
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  if (!_isPasswordState) ...[
                    // 大頭照選擇
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            _avatarFile != null
                                ? FileImage(_avatarFile!)
                                : null,
                        child:
                            _avatarFile == null
                                ? const Icon(Icons.camera_alt, size: 40)
                                : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // email
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '使用者帳號',
                        helperText: '請輸入您的email',
                      ),
                      onChanged: (_) {
                        if (_errorMessage.isNotEmpty) {
                          setState(() => _errorMessage = '');
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 暱稱
                    TextField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '使用者暱稱',
                        helperText: '請輸入暱稱',
                      ),
                      onChanged: (_) {
                        if (_errorMessage.isNotEmpty) {
                          setState(() => _errorMessage = '');
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 地區
                    buildLocationField(),
                    const SizedBox(height: 16),

                    // 偏好活動
                    buildPreferType(),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      child: const Text('下一步'),
                    ),
                  ],

                  if (_isPasswordState) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isPasswordState = false;
                            _passwordController.clear();
                          });
                        },
                        child: const Text('← 上一步'),
                      ),
                    ),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '設定密碼',
                        helperText: '請輸入密碼',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '設定密碼',
                        helperText: '請再次輸入密碼',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitRegister,
                      child:
                          _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('註冊完成'),
                    ),
                  ],

                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
