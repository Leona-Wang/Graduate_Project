"""使用方式
1. class 名稱： function 或 class 名稱+test(例如 class 叫 ABC -> ABCTest)
2. method 務必以 test 開頭(test case 基本上都是給 GPT 寫，只需要記得用 lower camel case 寫就好)
3.呼叫方式：
    -只測試單一 class ：python manage.py test tests.backend.viewsTest.class名(例如python manage.py test tests.backend.viewsTest.CaseTest)
    -測全部：python manage.py test tests.backend.viewsTest
"""

from django.test import TestCase


class CaseTest(TestCase):

    def setUp(self):
        self.integer = 1

    def testFileCanUse(self):
        testInt = self.integer
        self.assertEqual(testInt, 1)
