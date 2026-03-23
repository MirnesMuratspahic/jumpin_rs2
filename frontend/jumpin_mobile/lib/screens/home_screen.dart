import 'package:flutter/material.dart';
import '../models/ad.dart';
import '../providers/ad_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/auth_provider.dart';
import 'ad_details_screen.dart';
import 'add_ad_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthProvider authProvider;

  const HomeScreen({
    super.key,
    required this.authProvider,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _adProvider = AdProvider();
  final _recommendationProvider = RecommendationProvider();
  List<Ad> _ads = [];
  List<Ad> _recommendedAds = [];
  bool _isLoading = true;
  String? _selectedAdType;
  bool _showMyAdsOnly = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  static const Color _primaryColor = Color(0xFF1565C0);

  final List<Map<String, dynamic>> _adTypes = [
    {'name': 'Route', 'icon': Icons.route, 'value': 'Route'},
    {'name': 'Car', 'icon': Icons.directions_car, 'value': 'CarRental'},
    {'name': 'Apartment', 'icon': Icons.apartment, 'value': 'ApartmentRental'},
  ];

  @override
  void initState() {
    super.initState();
    _adProvider.setToken(widget.authProvider.token);
    _recommendationProvider.setToken(widget.authProvider.token);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserId = widget.authProvider.currentUser?.id;
      final ads = await _adProvider.getAds(
        adType: _selectedAdType,
        userId: _showMyAdsOnly ? currentUserId : null,
        isActive: _showMyAdsOnly ? null : true,
      );

      List<Ad> recommended = [];
      if (widget.authProvider.currentUser != null) {
        recommended = await _recommendationProvider.getRecommendations(
          widget.authProvider.currentUser!.id,
          count: 6,
        );
      }

      setState(() {
        _ads = ads;
        _recommendedAds =
            recommended.isNotEmpty ? recommended : ads.take(6).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Ad> get _filteredAds {
    var filtered = _ads;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((ad) {
        return ad.title.toLowerCase().contains(_searchQuery) ||
            (ad.description?.toLowerCase().contains(_searchQuery) ?? false) ||
            (ad.locationFrom?.toLowerCase().contains(_searchQuery) ?? false) ||
            (ad.locationTo?.toLowerCase().contains(_searchQuery) ?? false) ||
            (ad.location?.toLowerCase().contains(_searchQuery) ?? false) ||
            (ad.carBrand?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    return filtered;
  }

  Future<void> _deleteAd(Ad ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ad'),
        content: Text('Are you sure you want to delete "${ad.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _adProvider.deleteAd(ad.id);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad deleted successfully'), backgroundColor: Colors.green),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete the ad. Please try again later.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editAd(Ad ad) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAdScreen(
          authProvider: widget.authProvider,
          editAd: ad,
        ),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Color _getAdTypeColor(String adType) {
    switch (adType.toLowerCase()) {
      case 'route':
        return Colors.blue[700]!;
      case 'carrental':
      case 'car':
        return Colors.orange[700]!;
      case 'apartmentrental':
      case 'apartment':
        return Colors.green[700]!;
      default:
        return _primaryColor;
    }
  }

  IconData _getAdTypeIcon(String adType) {
    switch (adType.toLowerCase()) {
      case 'route':
        return Icons.route;
      case 'carrental':
      case 'car':
        return Icons.directions_car;
      case 'apartmentrental':
      case 'apartment':
        return Icons.apartment;
      default:
        return Icons.article;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _primaryColor),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: _primaryColor,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, ${widget.authProvider.currentUser?.firstName ?? 'User'}!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Find your next ride or stay',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.authProvider.currentUser?.isVip == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.amber, Colors.orange],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star, size: 16, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'VIP',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value.toLowerCase();
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search ads...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 50,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 18,
                                      color: _showMyAdsOnly ? Colors.white : Colors.deepOrange,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('My Ads'),
                                  ],
                                ),
                                selected: _showMyAdsOnly,
                                onSelected: (selected) {
                                  setState(() {
                                    _showMyAdsOnly = selected;
                                  });
                                  _loadData();
                                },
                                backgroundColor: Colors.white,
                                selectedColor: Colors.deepOrange,
                                labelStyle: TextStyle(
                                  color: _showMyAdsOnly ? Colors.white : Colors.deepOrange,
                                ),
                                checkmarkColor: Colors.white,
                              ),
                            ),
                            ..._adTypes.map((adType) {
                              final isSelected = _selectedAdType == adType['value'];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Row(
                                    children: [
                                      Icon(
                                        adType['icon'],
                                        size: 18,
                                        color: isSelected ? Colors.white : _primaryColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(adType['name']),
                                    ],
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedAdType = selected ? adType['value'] : null;
                                    });
                                    _loadData();
                                  },
                                  backgroundColor: Colors.white,
                                  selectedColor: _primaryColor,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : _primaryColor,
                                  ),
                                  checkmarkColor: Colors.white,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    if (_recommendedAds.isNotEmpty && _searchQuery.isEmpty && !_showMyAdsOnly) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: const Text(
                            'Recommended For You',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _recommendedAds.take(6).length,
                            itemBuilder: (context, index) {
                              return _buildRecommendedCard(
                                _recommendedAds[index],
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _showMyAdsOnly
                                  ? 'My Ads'
                                  : _selectedAdType != null
                                      ? '${_adTypes.firstWhere((t) => t['value'] == _selectedAdType)['name']} Ads'
                                      : 'All Ads',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_filteredAds.length} results',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    _filteredAds.isEmpty
                        ? SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No ads found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try changing your filters or search query',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildAdCard(_filteredAds[index]);
                              },
                              childCount: _filteredAds.length,
                            ),
                          ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddAdScreen(authProvider: widget.authProvider),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Ad'),
      ),
    );
  }

  Widget _buildRecommendedCard(Ad ad) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdDetailsScreen(
              ad: ad,
              authProvider: widget.authProvider,
            ),
          ),
        );
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getAdTypeColor(ad.adType).withAlpha(40),
                          _getAdTypeColor(ad.adType).withAlpha(80),
                        ],
                      ),
                    ),
                    child: ad.imageUrl != null && ad.imageUrl!.isNotEmpty
                        ? Image.network(
                            ad.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                _getAdTypeIcon(ad.adType),
                                size: 40,
                                color: _getAdTypeColor(ad.adType),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              _getAdTypeIcon(ad.adType),
                              size: 40,
                              color: _getAdTypeColor(ad.adType),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getAdTypeColor(ad.adType),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ad.adTypeDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (ad.isVipOwner)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ad.locationDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ad.price != null
                        ? '${ad.price!.toStringAsFixed(2)} KM'
                        : 'Price on request',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdCard(Ad ad) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdDetailsScreen(
              ad: ad,
              authProvider: widget.authProvider,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: ad.isVipOwner
              ? Border.all(color: Colors.amber, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getAdTypeColor(ad.adType).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getAdTypeIcon(ad.adType),
                      color: _getAdTypeColor(ad.adType),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ad.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getAdTypeColor(ad.adType),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ad.adTypeDisplay,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ad.locationDisplay,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.grey[300],
                        child: ad.userProfileImage != null
                            ? ClipOval(
                                child: Image.network(
                                  ad.userProfileImage!,
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ad.userName ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (ad.isVipOwner) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                      ],
                      if (ad.userRating != null && ad.userRating! > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          ad.userRating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      if (_showMyAdsOnly) ...[
                        GestureDetector(
                          onTap: () => _editAd(ad),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _primaryColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.edit, size: 18, color: _primaryColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _deleteAd(ad),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete, size: 18, color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        ad.price != null
                            ? '${ad.price!.toStringAsFixed(2)} KM'
                            : 'Price on request',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
