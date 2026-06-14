class AdImage {
  final String id;
  final String imageUrl;
  final bool isMainImage;
  final int displayOrder;
  final String adId;

  AdImage({
    required this.id,
    required this.imageUrl,
    this.isMainImage = false,
    this.displayOrder = 0,
    required this.adId,
  });

  factory AdImage.fromJson(Map<String, dynamic> json) {
    return AdImage(
      id: json['id'].toString(),
      imageUrl: json['imageUrl'] ?? '',
      isMainImage: json['isMainImage'] ?? false,
      displayOrder: json['displayOrder'] ?? 0,
      adId: json['adId'].toString(),
    );
  }
}
