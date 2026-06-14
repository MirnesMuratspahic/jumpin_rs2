class City {
  String? id;
  String? name;
  double? latitude;
  double? longitude;

  City({this.id, this.name, this.latitude, this.longitude});

  City.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    name = json['name'];
    latitude = (json['latitude'] as num?)?.toDouble();
    longitude = (json['longitude'] as num?)?.toDouble();
  }
}
