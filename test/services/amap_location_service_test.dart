import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/services/amap_location_service.dart';

void main() {
  test('直辖市 city 为空数组时安全兜底（北京场景回归）', () {
    final regeocode = {
      'formatted_address': '北京市东城区东华门街道台基厂头条3号中国国际问题研究院',
      'addressComponent': {
        'city': <dynamic>[],
        'province': '北京市',
        'district': '东城区',
        'township': '东华门街道',
        'streetNumber': {'street': '台基厂头条', 'number': '3号'},
      },
      'pois': [
        {'name': '中国国际问题研究院'},
      ],
      'aois': [],
    };

    final addr = AmapAddress.fromRegeo(regeocode);

    expect(addr.city, '');
    expect(addr.province, '北京市');
    expect(addr.district, '东城区');
    expect(addr.fullAddress, contains('台基厂头条'));
    expect(addr.shortAddress, '东城区东华门街道台基厂头条3号');
    expect(addr.nearbyPois, contains('中国国际问题研究院'));
  });

  test('普通城市正常解析', () {
    final regeocode = {
      'formatted_address': '浙江省杭州市西湖区文一西路100号',
      'addressComponent': {
        'city': '杭州市',
        'province': '浙江省',
        'district': '西湖区',
        'township': '',
        'streetNumber': {'street': '文一西路', 'number': '100号'},
      },
      'pois': [],
      'aois': [
        {'name': '某小区'},
      ],
    };

    final addr = AmapAddress.fromRegeo(regeocode);

    expect(addr.city, '杭州市');
    expect(addr.province, '浙江省');
    expect(addr.nearbyPois, contains('某小区'));
  });
}
